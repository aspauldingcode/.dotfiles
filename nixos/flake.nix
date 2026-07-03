# Installed to /etc/nixos/flake.nix by scripts/install-sliceanddice.sh.
# Lets `nh os switch` work from /etc/nixos while the repo lives in .dotfiles/.
{
  description = "NixOS entrypoint — delegates to /etc/nixos/.dotfiles";

  inputs.dotfiles.url = "path:/etc/nixos/.dotfiles";

  outputs = { dotfiles, ... }: dotfiles.outputs;
}
