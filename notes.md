# Notes
A few notes about my configuration in case I get lost.

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

#Pull the changes:
git pull

# Update Your Local Branch:
git checkout main
git merge origin/main

# Commit Your Changes (if needed):
git add .
git commit -m "Updating .dotfiles"

# Push the Changes to the Remote Repository:
git push origin main
```
## Darwin - Specific
While many things have been implemented into nix-darwin, there are many features left to be functional.
One of them is setting the default shell on macos.
How to add Fish Shell as default on mac?
`which fish`
for me, my fish was installed to: /Users/alex/.nix-profile/bin/fish

`sudo nvim /etc/shells`
Requires sudo. add your output from which fish command above to the end of the file.

`chsh -s /Users/alex/.nix-profile/bin/fish`
Since my path to my Fish shell was /Users/alex/.nix-profile/bin/fish. Put yours.

`sudo reboot`
reboot for changes to take effect.

Silence "Last login: tty000" motd: 
`touch ~/.hushlogin`
