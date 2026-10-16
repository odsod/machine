# Endpoint Verification

## Design

- Install Google's upstream `.deb` (`apihelper`, Chrome native messaging
  manifest, and `endpoint-verification.service`), pinned by
  `endpoint_verification_version`, `endpoint_verification_deb`, and
  `endpoint_verification_sha256` in `mise/conf.d/endpoint-verification.toml`.
- Replace `/opt/google/endpoint-verification/bin/device_state.sh` with the
  repo's POSIX `sh` script (`endpoint-verification/device_state.sh`) instead of
  patching the upstream script with `sed`.
- `device_state.sh` reports Fedora `VERSION_ID` from `/etc/os-release`, LUKS on
  btrfs subvolumes via `findmnt` + `lsblk`, KDE Plasma screen lock via
  `kreadconfig6`/`kreadconfig5`, and firewall state via `firewall-cmd`/`systemctl`.
- Label `/opt/google/endpoint-verification/var` and `.../var/lib` as `var_lib_t`
  so Fedora SELinux allows `init_t` to write `device_attrs`.
- Restart `endpoint-verification.service` on install (`RemainAfterExit=yes`
  otherwise keeps stale `device_attrs`).

## Verification

- Check script syntax and lint: `shellcheck endpoint-verification/device_state.sh && sh -n endpoint-verification/device_state.sh`
- Install and verify signals: `mise run endpoint-verification:install && mise run endpoint-verification:verify`
- Expected output: `disk_encrypted: ENABLED`, `os_version: "44"`,
  `screen_lock_secured: ENABLED`, `os_firewall: "enabled"`.

## Known Limitation: Btrfs on LUKS in Chrome

- Chromium's `GetDiskEncrypted()` (`platform_utils_linux.cc`) runs `stat("/")`
  and checks `/sys/dev/block/<major>:0/dm/uuid`.
- Btrfs subvolumes use anonymous block devices (`major = 0`), so Chrome returns
  `SettingValue::DISABLED` instead of `UNKNOWN`.
- Because Chrome returns a non-empty `DISABLED` value, the Endpoint Verification
  extension never consults the native helper fallback (even though
  `device_state.sh` reports `disk_encrypted: ENABLED`).
- Workaround in Google Workspace Admin Console: add a file attribute check for
  `/sys/block/dm-0/dm/uuid` (`PresenceValue.VALUE_FOUND`).
