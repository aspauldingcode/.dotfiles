# Transport status — Sword 15 keyboard backlight on Linux

**Updated:** 2026-07-17

## Verdict

**Lighting control on Linux is blocked on a missing HID transport**, not on missing userspace packet code.

| Path                                            | Status                                                                             |
| ----------------------------------------------- | ---------------------------------------------------------------------------------- |
| `msi-ec` `msiacpi::kbd_backlight` (EC `0xd3`)   | **Banned** — EC hard-hang on write; LEDs stay dark even when `0xd3` already cycles |
| MSIKLM `1770:FF00` feature reports              | Implemented in `dendritic-sword-kbd-bl` — **no such device** on Linux today        |
| Factory `1038:20xx` (`ssdevfactory` / `msihid`) | Exists only under Windows after SSE drivers — **not present** under Linux          |
| In-kernel `hid-steelseries` MSI KLC `1038:1122` | Different generation (Raider A18); not enumerated here                             |

Until a Windows capture proves which VID/PID + reports actually light this Sword, we **do not** invent an EC shim and **do not** re-enable `msi-ec` kbd LED registration.

## What shipped in the flake

1. **Capture kit** — `docs/re/sword-kbd-bl/CAPTURE.md` + scripts staged to `C:\dendritic\re\` by `dendritic-windows-stage-kbd-re.service` (or manual copy).
2. **Static RE** — [PROTOCOL.md](PROTOCOL.md) (stack, IOCTLs, prior-art packets).
3. **Linux tool** — `dendritic-sword-kbd-bl` probes known HID IDs, sends MSIKLM-style level packets when a device opens, otherwise exits `2` (device missing). **Never writes EC.**
4. **niri** — Mod+F9 / XF86 kbd brightness call the tool (fails soft if no HID).

## Next step (human + Windows)

1. Boot Windows; confirm backlight works with SteelSeries Engine.
2. Follow [CAPTURE.md](CAPTURE.md); commit captures under `captures/`.
3. Update PROTOCOL.md with the live report layout; extend `dendritic-sword-kbd-bl` if PID ≠ `1770:FF00`.
4. Only then consider a Linux factory/compat shim — and only if the transport is **not** the banned EC offsets.

## Windows-only until then

Keyboard backlight remains a **Windows (SteelSeries Engine) feature** on this dual-boot. Linux Fn mapping (`KEYBOARD_KEY_8e` → `kbdillumtoggle`) stays for compositor keys; it does not illuminate LEDs without HID.
