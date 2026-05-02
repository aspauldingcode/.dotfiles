#!/nix/store/f700nj7wlwg441h39gkq29qbviy99sgq-bash-5.3p9/bin/bash
set -eou pipefail

PATH=$PATH:/nix/store/nixxlz2dfdwmy6r8da5sas4nrnj7sq3z-coreutils-9.10/bin:/nix/store/3bc6aq2x9iljanglimd651hvz2g0kfr9-e2fsprogs-1.47.3-bin/bin
if [ ! -e '/Users/8amps/.local/share/microvm/dendritic-vm.img' ]; then
  touch '/Users/8amps/.local/share/microvm/dendritic-vm.img'
  # Mark NOCOW
  chattr +C '/Users/8amps/.local/share/microvm/dendritic-vm.img' || true
  truncate -s 10240M '/Users/8amps/.local/share/microvm/dendritic-vm.img'
  mkfs.ext4   '/Users/8amps/.local/share/microvm/dendritic-vm.img'
fi

# Open macvtap interface file descriptors

runtime_args=

exec -a "microvm@dendritic-vm" /nix/store/n6r2khp10lr1vzr2chbx8ipy861s2dqi-qemu-for-vm-tests-10.2.2/bin/qemu-system-aarch64 -name dendritic-vm -M 'virt,accel=hvf:tcg,gic-version=max' -m 2047 -smp 2 -nodefaults -no-user-config -no-reboot -kernel /nix/store/rpxxxpb5i7z4xqrab5337avd6j9cqr2g-linux-6.18.24/Image -initrd /nix/store/lgdrb24s7b6d8bfgrxsl5y4l6mzg39mv-initrd-linux-6.18.24/initrd -chardev 'stdio,id=stdio,signal=off' -device virtio-rng-pci -smbios 'type=1,uuid=94cd2fa1-bc49-4534-c68c-051bd7ecfc7b'  -serial chardev:stdio -cpu host -append 'console=ttyAMA0 reboot=t panic=-1 8250.nr_uarts=1 loglevel=4 lsm=landlock,yama,bpf vt.default_red=0x2d,0xf9,0x8a,0xf0,0xb0,0xcc,0x30,0xe0,0x9d,0xf9,0x8a,0xf0,0xb0,0xcc,0x30,0xfc vt.default_grn=0x30,0x90,0xb3,0xc2,0xa4,0xa4,0xdf,0xf0,0xa8,0x90,0xb3,0xc2,0xa4,0xa4,0xdf,0xfe vt.default_blu=0x2f,0x6f,0x61,0x39,0xe3,0xe3,0xf3,0xef,0xa3,0x6f,0x61,0x39,0xe3,0xe3,0xf3,0xfd init=/nix/store/7wr5nsflpng71iv0xiyaqgn2v9szxndf-nixos-system-dendritic-vm-26.05.20260427.1c3fe55/init regInfo=/nix/store/8ijdgxnfjga9r6iqkzc02h11wmv3cbai-closure-info/registration' -nographic -qmp unix:dendritic-vm.sock,server,nowait -drive 'id=vda,format=raw,file=/Users/8amps/.local/share/microvm/dendritic-vm.img,if=none,aio=threads,discard=unmap,cache=none,read-only=off' -device 'virtio-blk-pci,drive=vda' -fsdev 'local,id=fs0,path=/nix/store,security_model=none,readonly=false' -device 'virtio-9p-pci,fsdev=fs0,mount_tag=ro-store' -device 'vhost-vsock-pci,guest-cid=4' ${runtime_args:-}

