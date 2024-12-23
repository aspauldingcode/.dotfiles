# .dotfiles
A Universal .dotfiles Configuration with Nix Flakes - over-engineered by Alex Spaulding.

## How much code?
👨‍💻 There are 1,614,176 lines of code in this repo. Last updated: Mon Dec 23 22:04:56 PST 2024

## Getting Started
This repo contains my ___nixified___ .dotfiles, which additionally defines the operating system environment for NixOS and Darwin.
__Note:__ this repo was not designed to be installed for other interested users.

### FRESH INSTALL
Please [read the Notes](notes.md) for info on what to do for a fresh install.

#### NIX Installer
- If you just set up a new mac, you should install Nix using the [Determinite Nix Installer](https://github.com/DeterminateSystems/nix-installer) which automatically enables Nix Flakes for us.
- If you just set up NixOS, you already have Nix, NixOS configuration.nix, and you'll need to enable flakes and home-manager.
- If you are [already using a different Linux Distro](https://nixos.wiki/wiki/Installing_from_Linux), you can install Nix, and the system setup will be different. You'll need to enable the nix daemon, and configure linux to support nix. 

#### Flakes
Since we are using a Flake-based .dotfiles config...

Ensure that you have enabled Flakes:
```bash
nix-env --version  # Ensure that you have Nix 2.4 or newer
nix --experimental-features 'nix-command flakes'  # Enable flakes
```

## Extra 
The install can be configured through the flake.nix.
Home-Manager Configuration is done per-user under Users/{user}/home.nix
If you're lost, please [read the Notes](notes.md) to follow setup.


# I'm being productive, I swear!
![macOS-NIXY](./macOS-NIXY.png)