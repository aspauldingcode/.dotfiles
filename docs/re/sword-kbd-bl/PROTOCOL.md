# Sword 15 A11UD — keyboard backlight protocol notes

**Chassis:** MSI Sword 15 A11UD / MS-1582 / EC `1582EMS1.107`  
**Hard ban (Linux):** never write EC `0xd3`, `0xf3`, or kbd mode `0x2c` (hard EC hang).  
See [`hosts/nixos/sliceanddice/msi-ec-sword-kbd-disable.patch`](../../../hosts/nixos/sliceanddice/msi-ec-sword-kbd-disable.patch).

## Windows stack (static RE)

```
ACPI\MSI0007 (PS/2)
  → ssps2.sys (upper filter)
  → ssdevfactory.sys (root) fabricates USB HID
       • SteelSeries Keyboard
       • SteelSeries MB Lighting Interface
  → msihid.sys on USB\VID_1038&PID_2000–203F&MI_01
  → \\.\steelseries_msihid  +  \\.\SSEngine
  → SSEdevice.dll (HandleHIDCmd / zone RGB / HidD_SetFeature)
  → SteelSeries Engine 3
```

Staged drivers: `C:\dendritic-drivers\steelseries-engine\`.

### Constants from binaries / INFs

| Item                      | Value                               | Source                         |
| ------------------------- | ----------------------------------- | ------------------------------ |
| PS/2 ACPI ID              | `MSI0007`                           | `ssps2.inf`                    |
| Factory HWID              | `root\ssdevfactory`                 | `ssdevfactory.inf`             |
| MSI HID VID/PID           | `1038:2000`–`203F` `&MI_01`         | `msihid.inf`                   |
| Device symlink            | `\\.\steelseries_msihid`            | `msihid.sys` / `SSEdevice.dll` |
| HID SET/GET feature IOCTL | `0x000B0191` / `0x000B0192`         | `SSEdevice.dll`                |
| Custom IOCTLs             | `0x222004`–`0x222014`, `0xDE0000xx` | `SSEdevice.dll` / `msihid.sys` |

`HandleHIDCmd` is a `DeviceChunk` dispatcher (cmd + length + payload) — **no static report templates** recovered from `SSEdevice.dll`. Zone validator builds 0x1C records from 0x14-stride RGB inputs (“bad zone RGB offset”). MSI `*.edevice` files are encrypted PEM `BEGIN DESCRIPTOR` blobs (high entropy).

## Prior-art HID (region RGB / MSIKLM)

Many older MSI SteelSeries notebooks use **8-byte HID feature reports** on **`VID 0x1770` / `PID 0xFF00`** ([MSIKLM](https://github.com/Gibtnix/MSIKLM)):

| Cmd               | Packet                                         |
| ----------------- | ---------------------------------------------- |
| Preset+brightness | `01 02 42 <region> <color> <brightness> 00 EC` |
| RGB               | `01 02 40 <region> R G B EC`                   |
| Mode commit       | `01 02 41 <mode> 00 00 00 EC`                  |

Brightness enum (cmd `0x42`): `0=high`, `1=medium`, `2=low`, `3=off`.  
Region: `1=left`, `2=middle`, `3=right` (plus logo/front/mouse on some SKUs).

Newer Raiders expose real USB **`1038:1122` (KLC)** / **`1038:1161` (ALC)** (in-kernel `hid-steelseries` work). Sword’s factory stack advertises **`1038:20xx`** instead — **confirm on Windows with capture**.

## Linux today

- No `1038:` or `1770:ff00` USB/HID device (factory never runs).
- `msi-ec` loaded; `msiacpi::kbd_backlight` intentionally **not** registered.
- EC `0xd3` may already read `0x80|level` while LEDs stay dark → enable path ≠ simple brightness byte.

## Capture required

See [CAPTURE.md](CAPTURE.md). Until `docs/re/sword-kbd-bl/captures/` has a pcap + NOTES with the live VID/PID and reports that change lighting, the Linux tool only **probes** known IDs and fails closed (no EC writes).
