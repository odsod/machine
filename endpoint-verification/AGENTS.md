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

## Known Limitations

### LUKS Encryption Detection on Btrfs (Linux)

**Status:** Chromium bug — unfixed as of Chrome 136 / June 2026.

#### Root Cause

Chrome's `GetDiskEncrypted()` in
`components/device_signals/core/common/linux/platform_utils_linux.cc`:

```cpp
SettingValue GetDiskEncrypted() {
  struct stat info;
  if (stat("/", &info) != 0) return UNKNOWN;
  int dev_major = major(info.st_dev);
  // Constructs: /sys/dev/block/<major>:0/dm/uuid
  // Checks if UUID starts with "crypt-"
}
```

On **btrfs-on-LUKS**, `stat("/")` returns `st_dev` with **major=0** because
btrfs subvolumes use anonymous block devices. Chrome constructs
`/sys/dev/block/0:0/dm/uuid` — which doesn't exist — and falls through to
`return SettingValue::DISABLED`.

On ext4-on-LUKS this works because `stat("/")` returns the dm-crypt device
number (major 253), which has a valid sysfs entry.

#### What Chrome should do

Walk `/proc/self/mountinfo` to resolve the backing device for `/`, then
check if that device's dm UUID starts with `CRYPT-`:

```text
# /proc/self/mountinfo shows:
46 1 0:37 /root / ... - btrfs /dev/mapper/luks-... ...
# The backing device /sys/block/dm-0/dm/uuid contains:
CRYPT-LUKS2-6290893e798343f2a19b9abf04c3b310-luks-...
```

#### Extension data flow (why the helper can't fix this)

```text
chrome.enterprise.reportingPrivate.getDeviceInfo()
  → diskEncrypted: SettingValue.DISABLED  (bug: wrong value)
  → rw() maps DISABLED → false
  → Xw(false) → proto enum 2 (NOT_ENCRYPTED)
  → Since value is non-empty, native helper fallback is never consulted
```

The native helper correctly reports `disk_encrypted: ENABLED`, but the
extension only calls it as a fallback when Chrome's API returns empty/null.
Since Chrome returns `DISABLED` (not empty), the fallback never fires.

#### Workarounds

**Option 1: Configurable file attribute (recommended)**

Use Endpoint Verification's "file or folder configuration" to detect
`/sys/block/dm-0/dm/uuid` presence. This file exists only when a
device-mapper device is active.

- Admin console → Devices → Mobile & endpoints → Settings → Universal
- Expand "Endpoint Verification configuration"
- Add file configuration:
  - Name: `luks-dm-uuid`
  - OS: Linux
  - Path: `/sys/block/dm-0/dm/uuid`
- Then create a Context-Aware Access level using:
  ```cel
  device.clients["bce"].data["file_config"]["luks-dm-uuid"]["presence"]
    == PresenceValue.VALUE_FOUND
  ```

**Limitation:** This proves a dm-crypt device exists, not that root is on
it. Also assumes `dm-0` (first device-mapper device) — fragile if the
numbering changes.

**Option 2: Accept the gap + risk register**

Document it as a known detection limitation. The native helper correctly
reports encryption — the data is available for manual audit even if the
Admin console shows "Not Encrypted".

**Option 3: File a Chromium bug**

File at https://issues.chromium.org/ against component
`Enterprise>Signals`. Include:

- Affected: btrfs-on-LUKS (Fedora, openSUSE, any distro with btrfs root)
- Source: `components/device_signals/core/common/linux/platform_utils_linux.cc`
- Fix: use `/proc/self/mountinfo` to resolve the backing device instead of
  `stat("/")` major number

## Gotchas

- `make -C endpoint-verification` restarts the oneshot service instead of only enabling it.
- Restart is required because `RemainAfterExit=yes` otherwise leaves stale `device_attrs`.
- Run `verify` with installed files; the Chrome extension reads the `/opt` helper path.
- Do not install the Mozilla native messaging manifest unless Firefox support is intentionally added.
