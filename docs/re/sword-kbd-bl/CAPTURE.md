# Windows capture procedure (Sword 15 kbd backlight)

Run **after** SteelSeries Engine + dendritic drivers installed and the keyboard lights work.

## 1. List HID devices

From an elevated PowerShell (script also staged at `C:\dendritic\re\list-hid.ps1`):

```powershell
Get-PnpDevice -Class HIDClass | Where-Object { $_.InstanceId -match 'VID_1038|VID_1770' } |
  Format-Table Status, Class, FriendlyName, InstanceId -AutoSize
```

Record every `VID_1038` / `VID_1770` InstanceId (PID + MI).

## 2. USBPcap / Wireshark

1. Install [USBPcap](https://desowin.org/usbpcap/) + Wireshark if missing.
2. Capture on the root hub that carries the SteelSeries / MB Lighting interfaces.
3. While capturing, perform in order (note timestamps):
   1. Fn backlight cycle (off → low → mid → high → off)
   2. Engine: set brightness only (white), each level
   3. Engine: set a solid color (optional RGB)
4. Stop capture. Export as `.pcapng`.

Filter examples:

- `usb.idVendor == 0x1038 || usb.idVendor == 0x1770`
- HID SET_REPORT / Feature

## 3. Optional read-only EC dump

If using RwEverything / similar: **read only**. Dump EC while **dark** and while **lit**. Diff regions **other than** `0xd3` (Fn already cycles that under Linux without lighting).

Do **not** write EC from any tool on this chassis.

## 4. Drop artifacts into the flake

Copy into the repo (from NixOS after boot):

```text
docs/re/sword-kbd-bl/captures/
  NOTES.md          # PIDs, timestamps, which action → which packets
  fn-cycle.pcapng
  engine-levels.pcapng   # optional
```

`NOTES.md` template is in that directory.

## 5. Success criteria for Phase 1

- [ ] At least one `1038:` or `1770:` device ID when lit
- [ ] Feature/output report bytes that change when brightness changes
- [ ] Report ID + length documented in NOTES.md
