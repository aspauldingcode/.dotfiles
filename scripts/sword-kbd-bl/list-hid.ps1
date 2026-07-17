# List SteelSeries / MSIKLM-like HID devices (Sword 15 kbd backlight RE).
# Run elevated optional; output is safe to paste into captures/NOTES.md.
$ErrorActionPreference = "Continue"
Write-Host "=== PnP HID VID_1038 / VID_1770 ==="
Get-PnpDevice -PresentOnly | Where-Object {
  $_.InstanceId -match 'VID_1038|VID_1770'
} | Format-Table -AutoSize Status, Class, FriendlyName, InstanceId

Write-Host "`n=== SetupAPI USB strings (wmic) ==="
Get-CimInstance Win32_PnPEntity | Where-Object {
  $_.DeviceID -match 'VID_1038|VID_1770'
} | Select-Object Name, DeviceID | Format-List
