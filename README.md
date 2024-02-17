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

## Extra 
The install can be configured through the flake.nix.
Home-Manager Configuration is done per-user under Users/{user}/home.nix
If you're lost, please [read the Notes](notes.md) to follow setup.

<details>
  <summary>Directory Tree:</summary>

```
.
├── README.md
├── \
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
    │   │   ├── nixvim.nix
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
    │   │   ├── nixvim.nix
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

22 directories, 98 files
```

</details>
