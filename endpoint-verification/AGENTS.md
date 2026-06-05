# endpoint-verification/

## Purpose

- Install Google Endpoint Verification native helper on Fedora.
- Use Google's Debian package as the upstream source.
- Replace only `device_state.sh` for Fedora compatibility.
- Keep `apihelper`, the Chrome native messaging manifest, and the systemd unit from the `.deb`.

## Approach

- Discover the latest package from Google's apt index:

  ```bash
  make -C endpoint-verification discover
  ```

- Download and verify the `.deb` with the upstream `SHA256` from the package index.
- Extract with `ar x` and `tar -xzf data.tar.gz` into:

  ```bash
  ~/.local/share/odsod/machine/data/endpoint-verification/<version>/extract
  ```

- Install files directly with `sudo install`:
  - `/opt/google/endpoint-verification/bin/apihelper`
  - `/opt/google/endpoint-verification/bin/device_state.sh`
  - `/etc/opt/chrome/native-messaging-hosts/com.google.endpoint_verification.api_helper.json`
  - `/lib/systemd/system/endpoint-verification.service`

## Fedora Patches

- Ship a full replacement `device_state.sh`; do not patch the downloaded script with `sed`.
- Keep the script POSIX `sh`; avoid Bash-only syntax.
- Fedora fixes:
  - `VERSION_ID` from `/etc/os-release`
  - LUKS detection through `findmnt` + `lsblk`, including BTRFS subvolumes
  - KDE Plasma screen lock through `kreadconfig6` / `kreadconfig5`
  - firewalld state through `firewall-cmd` / `systemctl`

## SELinux

- The bundled service writes `device_attrs` with:

  ```ini
  StandardOutput=file:/opt/google/endpoint-verification/var/lib/device_attrs
  ```

- Fedora SELinux blocks `init_t` from creating files under `/opt` labeled `usr_t`.
- The Makefile labels only the writable state directory:

  ```bash
  sudo chcon -t var_lib_t \
    /opt/google/endpoint-verification/var \
    /opt/google/endpoint-verification/var/lib
  ```

## Verification

- Run full install + verification:

  ```bash
  make -C endpoint-verification
  ```

- Run focused checks after script edits:

  ```bash
  shellcheck endpoint-verification/device_state.sh
  sh -n endpoint-verification/device_state.sh
  make -C endpoint-verification verify
  systemctl status endpoint-verification.service --no-pager
  ```

- Expected local signals:
  - `disk_encrypted: ENABLED`
  - `os_version: "44"` or current Fedora `VERSION_ID`
  - `screen_lock_secured: ENABLED`
  - `os_firewall: "enabled"`

## Gotchas

- `make -C endpoint-verification` restarts the oneshot service instead of only enabling it.
- Restart is required because `RemainAfterExit=yes` otherwise leaves stale `device_attrs`.
- Run `verify` with installed files; the Chrome extension reads the `/opt` helper path.
- Do not install the Mozilla native messaging manifest unless Firefox support is intentionally added.
