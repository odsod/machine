#!/bin/sh
# shellcheck disable=SC2016

set -u

AWK=/usr/bin/awk
CAT=/usr/bin/cat
CUT=/usr/bin/cut
DCONF=/usr/bin/dconf
FINDMNT=/usr/bin/findmnt
FIREWALL_CMD=/usr/bin/firewall-cmd
GREP=/usr/bin/grep
GSETTINGS=/usr/bin/gsettings
HOSTNAME_CMD=/usr/bin/hostname
KREADCONFIG6=/usr/bin/kreadconfig6
KREADCONFIG5=/usr/bin/kreadconfig5
LSBLK=/usr/bin/lsblk
PRINTF=/usr/bin/printf
SYSTEMCTL=/usr/bin/systemctl
TR=/usr/bin/tr

INSTALL_PREFIX=/opt/google/endpoint-verification
GENERATED_ATTRS_FILE="$INSTALL_PREFIX/var/lib/device_attrs"

ACTION=${1:-default}

SERIAL_NUMBER=
DISK_ENCRYPTED=UNKNOWN
OS_VERSION=
SCREENLOCK_ENABLED=UNKNOWN
HOSTNAME=
MODEL=
MAC_ADDRESSES=
OS_FIREWALL=unknown

log_error() {
  echo "$1" 1>&2
}

get_serial_number() {
  SERIAL_NUMBER_FILE=/sys/class/dmi/id/product_serial
  if [ -r "$SERIAL_NUMBER_FILE" ]; then
    SERIAL_NUMBER=$("$CUT" -c -128 "$SERIAL_NUMBER_FILE" | "$TR" -d '"')
  fi
}

strip_subvolume_suffix() {
  case "$1" in
    *'['*) "$PRINTF" '%s\n' "${1%%\[*}" ;;
    *) "$PRINTF" '%s\n' "$1" ;;
  esac
}

root_source() {
  if [ -x "$FINDMNT" ]; then
    "$FINDMNT" -n -o SOURCE / 2>/dev/null | "$AWK" 'NR == 1 { print }'
    return
  fi

  "$AWK" '$2 == "/" { print $1; exit }' /proc/mounts
}

is_crypt_or_has_crypt_parent() {
  DEVICE=$1

  case "$DEVICE" in
    /dev/*) ;;
    *) DEVICE=/dev/"$DEVICE" ;;
  esac

  while [ -n "$DEVICE" ]; do
    TYPE=$("$LSBLK" -dn -o TYPE "$DEVICE" 2>/dev/null | "$AWK" 'NR == 1 { print $1 }')
    case "$TYPE" in
      crypt) return 0 ;;
    esac

    PARENT=$("$LSBLK" -dn -o PKNAME "$DEVICE" 2>/dev/null | "$AWK" 'NR == 1 { print $1 }')
    case "$PARENT" in
      '') break ;;
      /dev/*) DEVICE=$PARENT ;;
      *) DEVICE=/dev/"$PARENT" ;;
    esac
  done

  return 1
}

get_disk_encrypted() {
  ROOT_SOURCE=$(root_source)
  ROOT_SOURCE=$(strip_subvolume_suffix "$ROOT_SOURCE")

  case "$ROOT_SOURCE" in
    '') DISK_ENCRYPTED=UNKNOWN ;;
    /dev/*)
      if is_crypt_or_has_crypt_parent "$ROOT_SOURCE"; then
        DISK_ENCRYPTED=ENABLED
      else
        DISK_ENCRYPTED=DISABLED
      fi
      ;;
    *)
      DISK_ENCRYPTED=UNKNOWN
      ;;
  esac
}

get_os_name_and_version() {
  OS_INFO_FILE=/etc/os-release
  if [ -r "$OS_INFO_FILE" ]; then
    OS_NAME=$("$GREP" -i '^NAME=' "$OS_INFO_FILE" | "$AWK" -F= '{ print $2 }' | "$TR" '[:upper:]' '[:lower:]')
    case "$OS_NAME" in
      *ubuntu*|*debian*|*fedora*)
        OS_VERSION=$("$GREP" -i '^VERSION_ID=' "$OS_INFO_FILE" | "$AWK" -F= '{ print $2 }' | "$TR" -d '"')
        ;;
      *)
        OS_VERSION=
        ;;
    esac
  else
    log_error "$OS_INFO_FILE is not available."
  fi
}

get_kde_screenlock_value() {
  LOCK_ENABLED=

  if [ -x "$KREADCONFIG6" ]; then
    LOCK_ENABLED=$("$KREADCONFIG6" --file kscreenlockerrc --group Daemon --key Autolock --default true 2>/dev/null || true)
  elif [ -x "$KREADCONFIG5" ]; then
    LOCK_ENABLED=$("$KREADCONFIG5" --file kscreenlockerrc --group Daemon --key Autolock --default true 2>/dev/null || true)
  fi

  case "$LOCK_ENABLED" in
    true) SCREENLOCK_ENABLED=ENABLED ;;
    false) SCREENLOCK_ENABLED=DISABLED ;;
    *) SCREENLOCK_ENABLED=UNKNOWN ;;
  esac
}

get_screenlock_value() {
  SESSION_SPEC=$(echo "${XDG_CURRENT_DESKTOP:-unset}""${DESKTOP_SESSION:-unset}" | "$TR" '[:upper:]' '[:lower:]')
  case "$SESSION_SPEC" in
    *cinnamon*) DESKTOP_ENV=cinnamon ;;
    *gnome*) DESKTOP_ENV=gnome ;;
    *unity*) DESKTOP_ENV=gnome ;;
    *kde*|*plasma*)
      get_kde_screenlock_value
      return
      ;;
    *)
      if [ -x "$KREADCONFIG6" ] || [ -x "$KREADCONFIG5" ]; then
        get_kde_screenlock_value
        return
      fi
      SCREENLOCK_ENABLED=UNKNOWN
      return
      ;;
  esac

  LOCK_ENABLED=
  if [ -x "$GSETTINGS" ]; then
    LOCK_ENABLED=$("$GSETTINGS" get org."$DESKTOP_ENV".desktop.screensaver lock-enabled 2>/dev/null || true)
  elif [ -x "$DCONF" ]; then
    LOCK_ENABLED=$("$DCONF" read /org/"$DESKTOP_ENV"/desktop/screensaver/lock-enabled 2>/dev/null || true)
    if [ "$LOCK_ENABLED" = "" ]; then
      LOCK_ENABLED=true
    fi
  fi

  case "$LOCK_ENABLED" in
    true) SCREENLOCK_ENABLED=ENABLED ;;
    false) SCREENLOCK_ENABLED=DISABLED ;;
    *) SCREENLOCK_ENABLED=UNKNOWN ;;
  esac
}

get_hostname() {
  if [ -x "$HOSTNAME_CMD" ]; then
    HOSTNAME=$("$HOSTNAME_CMD")
  fi
}

get_model() {
  MODEL_FILE=/sys/class/dmi/id/product_name
  if [ -r "$MODEL_FILE" ]; then
    MODEL=$("$CAT" "$MODEL_FILE")
  else
    log_error "$MODEL_FILE is not available."
  fi
}

get_all_mac_addresses() {
  SYS_CLASS_NET=/sys/class/net
  if [ -d "$SYS_CLASS_NET" ]; then
    MAC_ADDRESSES=$("$CAT" "$SYS_CLASS_NET"/*/address 2>/dev/null | "$GREP" -v '^$' | "$GREP" -v 00:00:00:00:00:00 || true)
  else
    log_error "$SYS_CLASS_NET is not available."
  fi
}

get_os_firewall() {
  if [ -x "$FIREWALL_CMD" ]; then
    FIREWALL_STATE=$("$FIREWALL_CMD" --state 2>/dev/null || true)
    case "$FIREWALL_STATE" in
      running)
        OS_FIREWALL=enabled
        return
        ;;
      not\ running)
        OS_FIREWALL=disabled
        return
        ;;
    esac
  fi

  if [ -x "$SYSTEMCTL" ]; then
    if "$SYSTEMCTL" is-active --quiet firewalld 2>/dev/null; then
      OS_FIREWALL=enabled
      return
    fi
    if "$SYSTEMCTL" list-unit-files firewalld.service >/dev/null 2>&1; then
      OS_FIREWALL=disabled
      return
    fi
  fi

  UFW_CONFIG_FILE=/etc/ufw/ufw.conf
  if [ -r "$UFW_CONFIG_FILE" ]; then
    OS_FIREWALL=$("$GREP" -i '^ENABLED=' "$UFW_CONFIG_FILE" | "$AWK" -F= '{ print $2 }' | "$TR" '[:upper:]' '[:lower:]')
  else
    log_error "No supported firewall state source is available."
  fi
}

case "$ACTION" in
  init)
    get_serial_number
    get_disk_encrypted

    "$PRINTF" "serial_number: \"%s\"\n" "$SERIAL_NUMBER"
    "$PRINTF" "disk_encrypted: %s\n" "$DISK_ENCRYPTED"

    exit 0
  ;;
esac

if [ -r "$GENERATED_ATTRS_FILE" ]; then
  "$CAT" "$GENERATED_ATTRS_FILE"
fi

get_os_name_and_version
get_screenlock_value
get_hostname
get_model
get_all_mac_addresses
get_os_firewall

"$PRINTF" "os_version: \"%s\"\n" "$OS_VERSION"
"$PRINTF" "screen_lock_secured: %s\n" "$SCREENLOCK_ENABLED"
"$PRINTF" "hostname: \"%s\"\n" "$HOSTNAME"
"$PRINTF" "model: \"%s\"\n" "$MODEL"
"$PRINTF" "os_firewall: \"%s\"\n" "$OS_FIREWALL"

echo "$MAC_ADDRESSES" | while IFS= read -r item
do
  "$PRINTF" "mac_addresses: \"%s\"\n" "$item"
done
