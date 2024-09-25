# Notes
A few notes about my configuration in case I get lost.

## NEW!
Only works on Darwin atm: Run this install script:
```bash
bash -c 'curl -O https://raw.githubusercontent.com/aspauldingcode/.dotfiles/main/install.sh && sudo chmod +x install.sh && bash install.sh'
```

#### SSH Keys
```
ssh-keygen -t ed25519 #(then add .ssh/id_ed25519.pub key to github). Done.
```

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
```

```bash
# NIXEDUP(aarch64-linux)
cd ~/.dotfiles
sudo nixos-rebuild switch --flake .#NIXEDUP
```

```bash
# NIXY(aarch64-darwin)
cd ~/.dotfiles
darwin-rebuild switch --flake .#NIXY
```