{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.neovim
  ];

  shellHook = ''
    export EDITOR=nvim

    echo "Note: Due to permission issues, you need to manually run the following commands outside of the Nix shell."
    echo "1. Switch the NixOS channel to unstable:"
    echo "   sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos"
    echo "   sudo nix-channel --update"
    echo "2. Upgrade the system:"
    echo "   sudo nixos-rebuild switch --upgrade"
    echo ""
    echo "After performing the steps, re-enter the Nix shell to continue."
  '';
}

