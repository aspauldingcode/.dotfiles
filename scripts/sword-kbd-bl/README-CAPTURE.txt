Sword 15 keyboard backlight — Windows capture kit
==================================================

1. Confirm keyboard backlight works (SteelSeries Engine / Fn).
2. PowerShell:  powershell -ExecutionPolicy Bypass -File C:\dendritic\re\list-hid.ps1
   Copy output into docs/re/sword-kbd-bl/captures/NOTES.md (from NixOS later).
3. USBPcap + Wireshark: capture while cycling Fn backlight and Engine brightness.
   See docs/re/sword-kbd-bl/CAPTURE.md in the flake.
4. Copy .pcapng files next to NOTES.md under docs/re/sword-kbd-bl/captures/.

DO NOT write Embedded Controller registers with RwEverything or similar.
