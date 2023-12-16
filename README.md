# .dotfiles
A personal, universal ___flake___-enabled .dotfiles system configuration - by Alex Spaulding 

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

- [ ] **TODO:** Fix nvim and LSP Configurations
- [ ] **TODO:** Figure out how to FIRST TIME install on ALL systems
- [ ] **TODO:** Build a mac FIRST-TIME install script with all my settings unrelated to nix
- [ ] **TODO:** Fix Waybar and Sketchybar Universal UX/UI Config
- [ ] **TODO:** Fix Karabiner Key Combos
- [ ] **TODO:** Fix skhd hotkeys
- [ ] **TODO:** learn direnv: https://direnv.net/
- [ ] **TODO:** Configure Zellij and plugins
- [ ] **TODO:** Fix SDDM HomeManager vs System config and login issues
- [ ] **TODO:** Fix SDDM Theme with a gitFetch derivation for Sonoma V2 Theme
- [ ] **TODO:** Universal UX for zsh/zshrc and bash/bashrc, maybe even for fish shell
- [ ] **TODO:** FIX mobile-nixos on NIXEDUP!
- [ ] **TODO:** Nixos NIXY configuration (for nixos on NIXY instead of macOS on NIXY) 
- [ ] **TODO:** Fix SSH configurations and setups!
- [ ] **TODO:** Fix Nix-Colors configurations!
- [ ] **TODO:** Nix-Colors scheme switcher for darkmode/lightmode!
- [ ] **TODO:** Get Su Su's account set up with plasma or gnome!
- [ ] **TODO:** Add and modify Sketchybar Plugins mentioned in Sketchybar configs!
- [ ] **TODO:** Clean up repo code 

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
│       ├── apple-fonts.nix
│       ├── darwin-configuration.nix
│       ├── defaults-macos.nix
│       ├── homebrew-pkgs.nix
│       ├── packages.nix
│       └── spacebar.nix
└── users
    ├── alex
    │   ├── extraConfig
    │   │   ├── grimshot
    │   │   │   ├── client.py
    │   │   │   └── server.py
    │   │   ├── nvim
    │   │   │   ├── options.lua
    │   │   │   ├── plugin
    │   │   │   │   ├── cmp.lua
    │   │   │   │   ├── cmp-tags.lua
    │   │   │   │   ├── feline.lua
    │   │   │   │   ├── gitsigns.lua
    │   │   │   │   ├── incline.lua
    │   │   │   │   ├── indent-blankline.lua
    │   │   │   │   ├── live_preview_mapping.vim
    │   │   │   │   ├── lsp.lua
    │   │   │   │   ├── neorg.lua
    │   │   │   │   ├── nvim-tree.lua
    │   │   │   │   ├── other.lua
    │   │   │   │   ├── statuscol.lua
    │   │   │   │   ├── telescope.lua
    │   │   │   │   ├── treesitter.lua
    │   │   │   │   └── winbar.lua
    │   │   │   └── test.norg
    │   │   └── wallpapers
    │   │       ├── BunnyCooks.jpg
    │   │       ├── ElkCooks.jpg
    │   │       ├── reference.png
    │   │       ├── synthwave-night-skyscrapers.jpg
    │   │       └── TigerCooks.jpg
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
    │   │   ├── shell.nix
    │   │   ├── sway.nix
    │   │   └── waybar.nix
    │   ├── NIXY
    │   │   ├── alacritty.nix
    │   │   ├── fish.nix
    │   │   ├── git.nix
    │   │   ├── home-NIXY.nix
    │   │   ├── karabiner.nix
    │   │   ├── nvim.nix
    │   │   ├── packages-NIXY.nix
    │   │   ├── sketchybar
    │   │   │   ├── icons.sh
    │   │   │   ├── plugins
    │   │   │   │   ├── apple.sh
    │   │   │   │   ├── battery.sh
    │   │   │   │   ├── cava.sh
    │   │   │   │   ├── cpu.sh
    │   │   │   │   ├── date.sh
    │   │   │   │   ├── mail.sh
    │   │   │   │   ├── ram.sh
    │   │   │   │   ├── reload_theme.sh
    │   │   │   │   ├── spaces.sh
    │   │   │   │   ├── speed.sh
    │   │   │   │   ├── spotify.sh
    │   │   │   │   ├── time.sh
    │   │   │   │   ├── volume_click.sh
    │   │   │   │   ├── volume.sh
    │   │   │   │   └── wifi.sh
    │   │   │   ├── sketchybar.nix
    │   │   │   └── sketchybarrc
    │   │   ├── yabai.nix
    │   │   └── zsh.nix
    │   └── windows-shortcuts.nix
    └── susu
        ├── home-NIXSTATION64.nix
        ├── home-NIXY.nix
        └── modules
            ├── NIXSTATION64
            │   └── packages-NIXSTATION64.nix
            ├── NIXY
            │   └── packages-NIXY.nix
            └── packages-UNIVERSAL.nix

21 directories, 85 files
</pre>
