
# MacOS theming with modified .car files, located under system resources:
/System/Library/CoreServices/SystemAppearance.bundle/Contents/Resources/

It is backed up to my `.dotfiles` repo, where I attempt to make an edited theme to:

- [ ] change colors based on nix-colors
- [ ] see if I can remove shadows
- [x] remove window borders
- [x] remove window buttons (using StopStopLightLight.bundle)
- [ ] round vs square corner toggle option?
- [ ] edit .car themes with nix instead of themeengine or with asset catelog tinkerer.

This will allow me to fully customize MacOS to be fully mine. 


NOTES from ThemeEngine V2 details that remounting the root filesystem as read/write isn't enough. must also disable SIP and authenticated-root using csrutl command. I will likely have to do this when I set up a new system to install macos with nix-darwin etc. from recovery.

ThemeEngine
===========

App for OS X Yosemite to edit .car files which allows for the possibility of theming.

V.3 Branch is for 11.0+

V.2 Branch is for 10.11+

Note for Big Sur users:
If you want to edit system .car files it is no longer enough to remount the boot volume as read/write.
You will need to follow the steps below:

1. Disable SIP and authenticated-root:
In recovery mode, open Terminal and enter

`csrutil disable`

`csrutil authenticated-root disable`

Then reboot into macOS.

2. Identify the System Volume Disk Device Name
Run the mount command in Terminal to identify the devices of your system volume snapshot. Look for the device mounted at “/“, which identifies the system volume disk.  In the following example, this disk is `/dev/disk4s5s1`.
```
/dev/disk4s5s1 on / (apfs, sealed, local, read-only, journaled)
devfs on /dev (devfs, local, nobrowse)
/dev/disk4s4 on /System/Volumes/VM (apfs, local, noexec, journaled, noatime, nobrowse)
/dev/disk4s2 on /System/Volumes/Preboot (apfs, local, journaled, nobrowse)
/dev/disk4s1 on /System/Volumes/Data (apfs, local, journaled, nobrowse)
```
To get the actual name of the system volume disk, remove the final “sX” from the device. In the preceding example, the name of the system volume disk is `/dev/disk4s5`.

NOTE: So, for myself, to rephrase this nonsense, I run `mount` in terminal, and find the disk "/dev/diskxsxsx on / (xxxxx)" which is /dev/disk3s3s1 for me, and the system volume disk is actually just `/dev/disk3s3` on my system.


3. Mount a Live Version of the System Volume
Run the mount command in Terminal to mount the system volume disk to a temporary location. When running the mount command, always include the nobrowse mount option to prevent Spotlight from indexing the volume.

`mkdir /Users/<YOUR USER NAME>/livemount`

`sudo mount -o nobrowse -t apfs  /dev/disk4s5 /Users/<YOUR USER NAME>/livemount`

NOTE: so, for myself, I will enter:

`mkdir /Users/alex/livemount`
`sudo mount -o nobrowse -t apfs /dev/disk3s3 /Users/alex/livemount`

4. Edit the files from `/Users/<YOUR USER NAME>/livemount`
5. Bless your livemount with `sudo bless --mount /Users/<YOUR USER NAME>/livemount --bootefi --create-snapshot`s

NOTE: for myself, I will type:

`sudo bless --mount /Users/alex/livemount --bootefi --create-snapshot`
I believe this will apply the changes I've made from livemount to the system.
