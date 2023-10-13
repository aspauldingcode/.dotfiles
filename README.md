# .dotfiles
Last commit: <!-- LAST_COMMIT_DATE -->

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

#### SSH Keys
You're gonna need ssh keys stored in ~/.ssh on your local machine. The public ssh key that syncs from this repo is "``.dotfiles-keys.pub``," and the private ssh key that syncs to this repo is "``.dotfiles-keys``." These files are responsible for allowing new git clones. Check BitWarden if you forget the passphrase.

#### Git Clone
Now, you'll need to run a quick series of commands.

Clone the .dotfiles repo:
```bash
git clone git@github.com:aspauldingcode/.dotfiles.git ~/.dotfiles 
# Be sure to enter ssh dotfiles-keys passphrase! 
```

### INSTALLING DOTFILES
We can install our configurations, based on the hostname of the computer.
NOTE: if adding a new computer, it's required to modify the "``flake.nix``" in order to support the new device, including the architecture and device hostname, as well as the desired users. In addition, you will need to add your device to a folder under "``system/hostname/``," which will contain your system "``configuration.nix``," and "``hardware-configuration.nix``."

#### Needed for first-time install(?)

**FIRST INSTALL based on Hostname**
```bash 
# NIXY(aarch64-darwin)
#NEEDED for FIRST INSTALL (LIKELY TO CHANGE IN THE FUTURE)
darwin-rebuild switch -I ~/.dotfiles/system/NIXY/darwin-configuration.nix
home-manager build --flake .#alex@NIXY
```
#### Rebuild Existing

it is now possible to rebuild using ONLY the following command:
``rebuild``

**REBUILD EXISITNG based on Hostname:**
```bash
# NIXSTATION64(x86_64-linux)
cd ~/.dotfiles
sudo nixos-rebuild switch --flake .#NIXSTATION64 
home-manager switch --flake .#alex@NIXSTATION64
```
```bash
# NIXEDUP(aarch64-linux)
cd ~/.dotfiles
sudo nixos-rebuild switch --flake .#NIXEDUP 
home-manager switch --flake .#alex@NIXEDUP
```
```bash
# NIXY(aarch64-darwin)
cd ~/.dotfiles
darwin-rebuild switch --flake .#NIXY
home-manager switch --flake .#alex@NIXY
```
## Updating the Repository
We want to keep all our software, user profile settings, and operating systems environments in sync. Github and git-cli just happens to offer the most convenient tools to do so.

It is now possible to update the repo using ONLY the following command:
``update``

```bash
# Navigate to the Repository Directory:
cd ~/.dotfiles

#Fetch the Latest Changes:
git fetch

# Update Your Local Branch:
git checkout main
git merge origin/main

# Commit Your Changes (if needed):
git add .
git commit -m "Updating .dotfiles"

# Push the Changes to the Remote Repository:
git push origin main
```

## Extra 
The install can be configured through the flake.nix.
Home-Manager Configuration is done per-user under Users/{user}/home.nix

As of <!-- LAST_COMMIT_DATE -->, the repo layout is as follows;

<pre>
.
├── README.md
├── flake.lock
├── flake.nix
├── system
│   ├── NIXEDUP
│   ├── NIXSTATION64
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   ├── packages-configuration.nix
│   │   ├── sddm-themes.nix
│   │   ├── sway-configuration.nix
│   │   └── virtual-machines.nix
│   └── NIXY
│       └── darwin-configuration.nix
└── users
    ├── alex
    │   ├── NIXEDUP
    │   │   ├── home-NIXEDUP.nix
    │   │   └── packages-NIXEDUP.nix
    │   ├── NIXSTATION64
    │   │   ├── home-NIXSTATION64.nix
    │   │   ├── packages-NIXSTATION64.nix
    │   │   └── synthwave-night-skyscrapers.jpg
    │   ├── NIXY
    │   │   ├── home-NIXY.nix
    │   │   ├── packages-NIXY.nix
    │   │   └── yabai.nix
    │   └── extraConfig
    │       ├── fish.nix
    │       ├── git.nix
    │       └── nvim
    │           └── init.lua
    └── susu
        ├── home-NIXSTATION64.nix
        ├── home-NIXY.nix
        └── modules
            ├── NIXSTATION64
            │   └── packages-NIXSTATION64.nix
            ├── NIXY
            │   └── packages-NIXY.nix
            └── packages-UNIVERSAL.nix

16 directories, 27 files
</pre>
