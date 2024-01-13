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

- [x] Fix Double Waybar Issue
- [x] Fix SDDM HomeManager vs System config and login issues
- [x] Fix SDDM Theme with a gitFetch derivation for Sonoma V2 Theme
- [x] Set Default xserver Session to SwayFX instead of Plasma Wayland or Plasma(x11)
- [x] Universal UX for zsh/zshrc
- [x] Configure Zellij
- [x] Fix zsh problems
- [x] Waybar and Sketchybar Universal UX/UI Config
- [x] Fix Karabiner Key Combos
- [x] Fix skhd hotkeys
- [x] Fix nix Alacritty package issues
- [ ] SDDM Background swap
- [ ] SDDM custom profile image, fetched from github profile
- [ ] Fix wayland timeout to SDDM instead of waylock
- [ ] Add Zellij plugins
- [ ] Fix bash problems
- [ ] Fix fish problems
- [ ] Fix zellij/sway  keybinds conflicts
- [ ] Fix zellij/yabai keybinds conflicts
- [ ] Fix nvim and LSP Configurations
- [ ] Overlay custom package for macOSInstantView driver with nix fetchers
- [ ] Figure out how to FIRST TIME install on ALL systems
- [ ] Build a mac FIRST-TIME install script with all my settings unrelated to nix
- [ ] Fix sketchybar mail plugin
- [ ] Fix sketchybar volume plugin
- [ ] Fix sketchybar waybar icons
- [ ] Fix sketchybar wifi pupup
- [ ] Fix sketchybar calendar plugin
- [ ] Fix sketchybar datetime icon
- [ ] Fix sketchybar bold workspace icon
- [ ] Add sketchybar tray seperator
- [ ] Add waybar tray seperator
- [ ] Add sketchybar currently playing plugin.
- [ ] Add sketchybar weather plugin
- [ ] Add sketchybar wallpaper setter plugin
- [ ] Add sketchybar darkmode scheme switch plugin
- [ ] Learn Kmonad and see if it's right for my usecase.
- [ ] Learn [direnv](https://direnv.net/)
- [ ] Learn LaTeX and vimtex plugin for nvim
- [ ] Install mobile-nixos on NIXEDUP
- [ ] Enable Flakes local config on NIXEDUP
- [ ] NixOS NIXY configuration (for nixos on NIXY instead of macOS on NIXY)
- [ ] Fix SSH configurations and setups!
- [ ] Fix Nix-Colors configurations!
- [ ] Nix-Colors scheme switcher for darkmode/lightmode on both systems!
- [ ] Get Su Su's account set up with plasma or gnome!
- [ ] Upgrade my Calendar Plugin for Sketchybar
- [ ] Complete Sketchybar Config
- [ ] Complete Waybar Config
- [ ] Are we UNIVERSAL yet?
- [ ] Clean up repo code 

## Extra 
The install can be configured through the flake.nix.
Home-Manager Configuration is done per-user under Users/{user}/home.nix
If you're lost, please [read the Notes](notes.md) to follow setup.

A preview of the repo layout:
<pre>
```
.
├── README.md
├── flake.lock
├── flake.nix
├── notes.md
├── system
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
│       └── yabai-sa.nix
└── users
    ├── alex
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
    │   │   ├── sway.nix
    │   │   ├── waybar.nix
    │   │   ├── zellij.nix
    │   │   └── zsh.nix
    │   ├── NIXY
    │   │   ├── alacritty.nix
    │   │   ├── cava.nix
    │   │   ├── fish.nix
    │   │   ├── git.nix
    │   │   ├── home-NIXY.nix
    │   │   ├── karabiner.nix
    │   │   ├── nvim.nix
    │   │   ├── packages-NIXY.nix
    │   │   ├── sketchybar
    │   │   │   ├── icons.sh
    │   │   │   ├── items
    │   │   │   │   └── calendar.sh
    │   │   │   ├── plugins
    │   │   │   │   ├── apple.sh
    │   │   │   │   ├── battery.sh
    │   │   │   │   ├── cava.conf
    │   │   │   │   ├── cava.sh
    │   │   │   │   ├── cpu.sh
    │   │   │   │   ├── datetime.sh
    │   │   │   │   ├── front_app.sh
    │   │   │   │   ├── mail.sh
    │   │   │   │   ├── ram.sh
    │   │   │   │   ├── reload_theme.sh
    │   │   │   │   ├── space.sh
    │   │   │   │   ├── speed.sh
    │   │   │   │   ├── spotify.sh
    │   │   │   │   ├── time.sh
    │   │   │   │   ├── volume.sh
    │   │   │   │   ├── volume_click.sh
    │   │   │   │   └── wifi.sh
    │   │   │   ├── sketchybar.nix
    │   │   │   └── sketchybarrc
    │   │   ├── yabai.nix
    │   │   ├── zellij.nix
    │   │   └── zsh.nix
    │   ├── extraConfig
    │   │   ├── cursors-macOS
    │   │   │   ├── com.ful1e5.bibatamodernice.cape
    │   │   │   └── com.maxrudberg.svanslosbluehazard.cape
    │   │   ├── grimshot
    │   │   │   ├── client.py
    │   │   │   └── server.py
    │   │   ├── nvim
    │   │   │   ├── options.lua
    │   │   │   ├── plugin
    │   │   │   │   ├── cmp-tags.lua
    │   │   │   │   ├── cmp.lua
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
    │   │       ├── TigerCooks.jpg
    │   │       ├── ghibliwp.jpg
    │   │       ├── reference.png
    │   │       ├── sketchybarTODAY.png
    │   │       └── synthwave-night-skyscrapers.jpg
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

22 directories, 95 files
```
</pre>
