{ nixpkgs, system, ... }:

let
  pkgs = nixpkgs.legacyPackages.${system};

  fakeOpenSSH = pkgs.writeShellScriptBin "ssh" ''
    #!/bin/sh
    out="''${SSH_ARGS_OUT:?SSH_ARGS_OUT must be set}"
    : > "$out"
    for arg in "$@"; do
      printf '%s\n' "$arg" >> "$out"
    done
  '';

  fakeSystemctl = pkgs.writeShellScriptBin "systemctl" ''
    if [[ $1 == is-active ]]; then
      exit 0
    else
      exit 1
    fi
  '';

  microvmCommand = pkgs.callPackage ../pkgs/microvm-command.nix {
    openssh = fakeOpenSSH;
    stateDir = "/tmp/microvms";
  };
in
{
  microvm-command =
    pkgs.runCommandLocal "microvm-command"
      {
        nativeBuildInputs = [
          microvmCommand
          pkgs.diffutils
          fakeSystemctl
        ];
      }
      ''
        set -euo pipefail

        mkdir -p /tmp/microvms/vm/current/share/microvm
        echo 4242 > /tmp/microvms/vm/current/share/microvm/vsock-cid
        echo qemu > /tmp/microvms/vm/current/share/microvm/hypervisor

        export SSH_ARGS_OUT="$PWD/ssh-args-extra-opts"
        microvm -s vm -- -l root -i /tmp/test-key
        cat > "$PWD/expected-extra-opts" <<'EOF'
        -o
        StrictHostKeyChecking=no
        -o
        UserKnownHostsFile=/dev/null
        vsock/4242
        -l
        root
        -i
        /tmp/test-key
        EOF
        diff -u "$PWD/expected-extra-opts" "$PWD/ssh-args-extra-opts"

        export SSH_ARGS_OUT="$PWD/ssh-args-remote-cmd"
        microvm -s vm uname -a
        cat > "$PWD/expected-remote-cmd" <<'EOF'
        -o
        StrictHostKeyChecking=no
        -o
        UserKnownHostsFile=/dev/null
        vsock/4242
        -l
        root
        uname
        -a
        EOF
        diff -u "$PWD/expected-remote-cmd" "$PWD/ssh-args-remote-cmd"

        mkdir $out
      '';
}
