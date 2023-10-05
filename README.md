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
<pre>
nix-env --version  # Ensure that you have Nix 2.4 or newer
nix --experimental-features 'nix-command flakes'  # Enable flakes
</pre>

- [ ] **TODO:** Check if I need to install home-manager first!

#### SSH Keys
You're gonna need ssh keys stored in ~/.ssh on your local machine. The public ssh key that syncs from this repo is "``.dotfiles-keys.pub``," and the private ssh key that syncs to this repo is "``.dotfiles-keys``." These files are responsible for allowing new git clones. Check BitWarden if you forget the passphrase.

#### Git Clone
Now, you'll need to run a quick series of commands.

Clone the .dotfiles repo:
<pre>
git clone git@github.com:aspauldingcode/.dotfiles.git ~/.dotfiles 
# Be sure to enter ssh dotfiles-keys passphrase! 
</pre>

### INSTALLING DOTFILES
We can install our configurations, based on the hostname of the computer.
NOTE: if adding a new computer, it's required to modify the "``flake.nix``" in order to support the new device, including the architecture and device hostname, as well as the desired users. In addition, you will need to add your device to a folder under "``system/hostname/``," which will contain your system "``configuration.nix``," and "``hardware-configuration.nix``."

**IMPORTANT**
- Navigate to the Repository Directory:
<pre>
cd ~/.dotfiles
</pre>

**Install based on Hostname:**
- NIXSTATION64(x86_64-linux)
<pre>
sudo nixos-rebuild switch --flake .#NIXSTATION64 
home-manager switch --flake .#alex@NIXSTATION64
</pre>
- NIXEDUP(aarch64-linux)
<pre>
sudo nixos-rebuild switch --flake .#NIXEDUP 
home-manager switch --flake .#alex@NIXEDUP
</pre>
- NIXY(aarch64-darwin)
<pre>
#NEEDED for FIRST INSTALL
darwin-rebuild switch -I ~/.dotfiles/system/NIXY/darwin-configuration.nix
home-manager build --flake .#alex@NIXY

#rebuild existing
darwin-rebuild switch --flake .#NIXY
home-manager switch --flake .#alex@NIXY
</pre>

## Updating the Repository
We want to keep all our software, user profile settings, and operating systems environments in sync. Github and git-cli just happens to offer the most convenient tools to do so.

- Navigate to the Repository Directory:
<pre>
cd ~/.dotfiles
</pre>
- Fetch the Latest Changes:
<pre>
git fetch
</pre>

- Update Your Local Branch:
```bash
git checkout main
git merge origin/main
```
- Commit Your Changes (if needed):
<pre>
git add .
git commit -m "Updating .dotfiles"
</pre>
- Push the Changes to the Remote Repository:
<pre>
git push origin main
</pre>

## Extra 
The install can be configured through the flake.nix.
Home-Manager Configuration is done per-user under Users/{user}/home.nix

As of <!-- LAST_COMMIT_DATE -->, the repo layout is as follows;

<pre>
~/.dotfiles> tree
.
├── README.md
├── extraConfig
│   └── nvim
│       └── init.lua
├── flake.lock
├── flake.nix
├── system
│   ├── NIXSTATION64
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   ├── packages-configuration.nix
│   │   └── sway-configuration.nix
│   └── NIXY
│       └── darwin-configuration.nix
└── users
    ├── alex
    │   ├── home.nix
    │   └── packages.nix
    └── susu
        ├── home.nix
        └── packages.nix

9 directories, 13 files
</pre>
