# .dotfiles
A Universal .dotfiles Configuration with Nix Flakes - over-engineered by Alex Spaulding.

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
├── flake.lock
├── flake.nix
├── install_script.sh
├── notes.md
├── system
│   ├── NIXEDUP
│   ├── NIXSTATION64
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   ├── packages.nix
│   │   ├── sddm-themes.nix
│   │   ├── sway-configuration.nix
│   │   ├── theme.nix
│   │   ├── virtual-machines.nix
│   │   └── wg-quick.nix
│   ├── NIXY
│   │   ├── apple-fonts.nix
│   │   ├── darwin-configuration.nix
│   │   ├── darwin-defaults.nix
│   │   ├── darwin-sudoers.nix
│   │   ├── homebrew-pkgs.nix
│   │   ├── instantview.nix
│   │   ├── packages.nix
│   │   ├── sa-resources
│   │   │   ├── README.md
│   │   │   ├── edited
│   │   │   │   ├── Aqua.car
│   │   │   │   ├── AquaAX.car
│   │   │   │   ├── DarkAqua.car
│   │   │   │   └── DarkAquaAX.car
│   │   │   └── original
│   │   │       ├── AccessibilitySystemAppearance.car
│   │   │       ├── Aqua.car
│   │   │       ├── AquaAX.car
│   │   │       ├── AquaVisibleBezels.car
│   │   │       ├── Assets.car
│   │   │       ├── ControlStripAppearance.car
│   │   │       ├── ControlStripCustomizationPaletteAppearance.car
│   │   │       ├── DarkAqua.car
│   │   │       ├── DarkAquaAX.car
│   │   │       ├── DarkAquaVisibleBezels.car
│   │   │       ├── DarkGraphite.car
│   │   │       ├── DarkGraphiteAX.car
│   │   │       ├── DebugAppearance.car
│   │   │       ├── FauxVibrantDark.car
│   │   │       ├── FauxVibrantDarkGraphite.car
│   │   │       ├── FauxVibrantLight.car
│   │   │       ├── FauxVibrantLightGraphite.car
│   │   │       ├── FunctionRowAppearance.car
│   │   │       ├── Graphite.car
│   │   │       ├── GraphiteAX.car
│   │   │       ├── InfoPlist.loctable
│   │   │       ├── SystemAppearance.car
│   │   │       ├── TouchBarCustomizationPaletteAppearance.car
│   │   │       ├── VibrantDark.car
│   │   │       ├── VibrantDarkAX.car
│   │   │       ├── VibrantDarkGraphite.car
│   │   │       ├── VibrantDarkGraphiteAX.car
│   │   │       ├── VibrantDarkVisibleBezels.car
│   │   │       ├── VibrantLight.car
│   │   │       ├── VibrantLightAX.car
│   │   │       ├── VibrantLightGraphite.car
│   │   │       ├── VibrantLightGraphiteAX.car
│   │   │       └── VibrantLightVisibleBezels.car
│   │   ├── theme.nix
│   │   ├── wg-quick.nix
│   │   └── yabai-sa.nix
│   └── extraConfig
│       ├── id_ed25519_NIXSTATION64.pub
│       └── id_ed25519_NIXY.pub
└── users
    ├── alex
    │   ├── NIXEDUP
    │   │   ├── home-NIXEDUP.nix
    │   │   └── packages-NIXEDUP.nix
    │   ├── NIXSTATION64
    │   │   ├── alacritty.nix
    │   │   ├── betterdiscord.nix
    │   │   ├── btop.nix
    │   │   ├── discocss.nix
    │   │   ├── fish.nix
    │   │   ├── git.nix
    │   │   ├── home-NIXSTATION64.nix
    │   │   ├── mako.nix
    │   │   ├── packages-NIXSTATION64.nix
    │   │   ├── sway.nix
    │   │   ├── theme.nix
    │   │   ├── waybar
    │   │   │   ├── silence.wav
    │   │   │   └── waybar.nix
    │   │   ├── zellij.nix
    │   │   └── zsh.nix
    │   ├── NIXY
    │   │   ├── alacritty.nix
    │   │   ├── betterdiscord.nix
    │   │   ├── btop.nix
    │   │   ├── cava.nix
    │   │   ├── fish.nix
    │   │   ├── git.nix
    │   │   ├── home-NIXY.nix
    │   │   ├── i3.nix
    │   │   ├── karabiner.nix
    │   │   ├── kitty.nix
    │   │   ├── neofetch.nix
    │   │   ├── packages-NIXY.nix
    │   │   ├── phoenix
    │   │   │   ├── phoenix.js
    │   │   │   └── phoenix.nix
    │   │   ├── sketchybar
    │   │   │   ├── icons.sh
    │   │   │   ├── plugins
    │   │   │   │   ├── apple.sh
    │   │   │   │   ├── battery.sh
    │   │   │   │   ├── cava.conf
    │   │   │   │   ├── cava.sh
    │   │   │   │   ├── cpu.sh
    │   │   │   │   ├── datetime.sh
    │   │   │   │   ├── front_app.sh
    │   │   │   │   ├── mail.sh
    │   │   │   │   ├── ram.sh
    │   │   │   │   ├── reload_theme.sh
    │   │   │   │   ├── space.sh
    │   │   │   │   ├── speed.sh
    │   │   │   │   ├── spotify.sh
    │   │   │   │   ├── time.sh
    │   │   │   │   ├── volume.sh
    │   │   │   │   └── wifi.sh
    │   │   │   ├── sketchybar.nix
    │   │   │   └── sketchybarrc
    │   │   ├── theme.nix
    │   │   ├── xcode
    │   │   │   ├── base16.xccolortheme
    │   │   │   └── xcode.nix
    │   │   ├── xinit.nix
    │   │   ├── yabai.nix
    │   │   ├── yazi
    │   │   │   ├── keymap.toml
    │   │   │   ├── theme.toml
    │   │   │   ├── yazi.nix
    │   │   │   └── yazi.toml
    │   │   ├── zellij.nix
    │   │   └── zsh.nix
    │   ├── extraConfig
    │   │   ├── bonjourr
    │   │   │   └── bonjourr.json
    │   │   ├── cursors-macOS
    │   │   │   ├── com.ful1e5.bibatamodernice.cape
    │   │   │   └── com.maxrudberg.svanslosbluehazard.cape
    │   │   ├── grimshot
    │   │   │   ├── client.py
    │   │   │   └── server.py
    │   │   ├── nvim
    │   │   │   ├── htmx-lsp.nix
    │   │   │   ├── nixvim.nix
    │   │   │   ├── options.lua
    │   │   │   ├── plugin
    │   │   │   │   ├── cmp-tags.lua
    │   │   │   │   ├── cmp.lua
    │   │   │   │   ├── feline.lua
    │   │   │   │   ├── gitsigns.lua
    │   │   │   │   ├── incline.lua
    │   │   │   │   ├── indent-blankline.lua
    │   │   │   │   ├── live_preview_mapping.vim
    │   │   │   │   ├── lsp.lua
    │   │   │   │   ├── lualine-lsp-progress.lua
    │   │   │   │   ├── neorg.lua
    │   │   │   │   ├── nvim-tree.lua
    │   │   │   │   ├── other.lua
    │   │   │   │   ├── scrollbar.lua
    │   │   │   │   ├── scrollview.lua
    │   │   │   │   ├── statuscol.lua
    │   │   │   │   ├── telescope.lua
    │   │   │   │   ├── treesitter.lua
    │   │   │   │   └── winbar.lua
    │   │   │   └── test.norg
    │   │   └── wallpapers
    │   │       ├── ghibliwp.jpg
    │   │       └── sweden.png
    │   ├── face.png
    │   └── windows-shortcuts.nix
    └── susu
        ├── face.png
        ├── home-NIXSTATION64.nix
        ├── home-NIXY.nix
        └── modules
            ├── NIXSTATION64
            │   └── packages-NIXSTATION64.nix
            ├── NIXY
            │   └── packages-NIXY.nix
            └── packages-UNIVERSAL.nix

30 directories, 161 files
```

</details>
