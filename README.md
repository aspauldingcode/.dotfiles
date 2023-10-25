# .dotfiles
A personal, universal flake.nix-enabled .dotfiles system configuration - by Alex Spaulding 

## Getting Started
This repo contains my .dotfiles, which additionally defines the operating system environment for NixOS and Darwin.

### FRESH INSTALL

#### NIX Installer
- If you just set up a new mac, you are going to need both Nix, and [Nix-Darwin](https://github.com/LnL7/nix-darwin). You should install Nix using the [Determinite Nix Installer](https://github.com/DeterminateSystems/nix-installer) which automatically enables Nix Flakes for us.

- If you just set up NixOS, you already have Nix, NixOS configuration.nix, and you'll need to enable flakes and home-manager.

- If you are [already using a different Linux Distro](https://nixos.wiki/wiki/Installing_from_Linux), you can install Nix, and the system setup will be different. You'll need to enable the nix daemon, and configure linux to support nix. 

#### Flakes
Since we are using a Flake-based .dotfiles config...

Ensure that you have enabled Flakes:
```bash
nix-env --version  # Ensure that you have Nix 2.4 or newer
nix --experimental-features 'nix-command flakes'  # Enable flakes
```

- [x] **TODO:** Check if I need to install home-manager first!
- [ ] **TODO** Figure out how to FIRST TIME install on ALL systems

## Extra 
The install can be configured through the flake.nix.
Home-Manager Configuration is done per-user under Users/{user}/home.nix
If you're lost, please [read the Notes](notes.md) to follow setup.

A preview of the repo layout:
<pre>
.
├── flake.lock
├── flake.nix
├── notes.md
├── README.md
├── system
│   ├── NIXEDUP
│   ├── NIXSTATION64
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   ├── packages.nix
│   │   ├── sddm-themes.nix
│   │   ├── sway-configuration.nix
│   │   └── virtual-machines.nix
│   └── NIXY
│       ├── darwin-configuration.nix
│       ├── defaults-macos.nix
│       ├── homebrew-pkgs.nix
│       ├── packages.nix
│       ├── sketchybar.nix
│       ├── skhd.nix
│       ├── spacebar.nix
│       └── yabai.nix
└── users
    ├── alex
    │   ├── extraConfig
    │   │   ├── iTerm2
    │   │   │   └── com.googlecode.iterm2.plist
    │   │   ├── nvim
    │   │   │   ├── options.lua
    │   │   │   └── plugin
    │   │   │       ├── cmp.lua
    │   │   │       ├── lsp.lua
    │   │   │       ├── other.lua
    │   │   │       ├── telescope.lua
    │   │   │       └── treesitter.lua
    │   │   ├── sway
    │   │   │   └── config.bk
    │   │   └── wallpapers
    │   │       └── synthwave-night-skyscrapers.jpg
    │   ├── NIXEDUP
    │   │   ├── home-NIXEDUP.nix
    │   │   └── packages-NIXEDUP.nix
    │   ├── NIXSTATION64
    │   │   ├── alacritty.nix
    │   │   ├── fish.nix
    │   │   ├── git.nix
    │   │   ├── home-NIXSTATION64.nix
    │   │   ├── mako.nix
    │   │   ├── nvim.nix
    │   │   ├── packages-NIXSTATION64.nix
    │   │   └── sway.nix
    │   └── NIXY
    │       ├── alacritty.nix
    │       ├── fish.nix
    │       ├── git.nix
    │       ├── home-NIXY.nix
    │       ├── nvim.nix
    │       └── packages-NIXY.nix
    └── susu
        ├── home-NIXSTATION64.nix
        ├── home-NIXY.nix
        └── modules
            ├── NIXSTATION64
            │   └── packages-NIXSTATION64.nix
            ├── NIXY
            │   └── packages-NIXY.nix
            └── packages-UNIVERSAL.nix

20 directories, 48 files
</pre>
