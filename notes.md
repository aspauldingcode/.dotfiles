# Notes
A few notes about my configuration in case I get lost.

# NEW!
run this install script:
```
TBD...
```

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




QUICK INFO DUMP:
As of 11/30/23, I've reinstalled macos.
I first started by opening safari, and navigating to my dotfiles repo.
Then, I installed Nix with Nix-Determinate Installer.
Then, I opened terminal, and typed "git". This prompts xcode-tools install, for git command.
Then, I git cloned the repo to my home directory.
Then, I cd into my local repo clone, and I ran nix flake update.
Then, I tried to use the nix flakes. I ran into problem, so I think I need nix-darwin.
So, I know I need `nix run nix-darwin -- switch --flake ~/.dotfiles/`. 
Then, I have access to nix-darwin.
But, I hit error: 
```
error: Unexpected files in /etc, aborting activation
The following files have unrecognized content and would be overwritten:

  /etc/zshenv

Please check there is nothing critical in these files, rename them by adding .before-nix-darwin to the end, and then try again.
```

I beleive it's fixable with: `sudo mv /etc/zshenv /etc/zshenv.before-nix-darwin`

EDIT: `sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin && sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin && sudo mv /etc/zshenv /etc/zshenv.before-nix-darwin`

So, I think I need to run that before I run the nix run nix-darwin -- switch --flake ~/.dotfiles/`

We face a problem with homebrew not being installed. 
I should install homebrew before I run the nix run command above.
`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

Warning: /opt/homebrew/bin is not in your PATH.

```
==> Next steps:
- Run these two commands in your terminal to add Homebrew to your PATH:
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/alex/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
```

I run that command.
Then, I run Nix Run Nix-darwin thing again above.
This time, It uses homebrew and installs some extra things.
Now, I should be able to use nix-darwin..

Now, I'm curious if rebuild works. So I try rebuild. If that doesn't work..
So I try the initial rebuild commands: 
```
#NEEDED for FIRST INSTALL (LIKELY TO CHANGE IN THE FUTURE)
darwin-rebuild switch -I ~/.dotfiles/system/NIXY/darwin-configuration.nix
home-manager build --flake .#alex@NIXY
```. 
zsh: command not found: darwin-rebuild
zsh: command not found: home-manager

So, I just use the regular non-flake nix-darwin installer:
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
./result/bin/darwin-installer
But that throws error AND I DON'T NEED TO INSTALL IT BECAUSE  nix-determinate installer says do not use the nix-darwin installer on a flake system, which is enabled by default by determinite-installer...


So, I run:

```
darwin-rebuild switch -I ~/.dotfiles/system/NIXY/darwin-configuration.nix                                               ~/.dotfiles
home-manager build --flake .#alex@NIXY
```

To which I get:
```darwin-rebuild switch -I ~/.dotfiles/system/NIXY/darwin-configuration.nix                                               ~/.dotfiles
home-manager build --flake .#alex@NIXY
building the system configuration...
warning: Nix search path entry '/nix/var/nix/profiles/per-user/root/channels' does not exist, ignoring
error: file 'darwin' was not found in the Nix search path (add it using $NIX_PATH or -I)

       at «none»:0: (source not available)
warning: Git tree '/Users/alex/.dotfiles' is dirty
trace: warning: optionsDocBook is deprecated since 23.11 and will be removed in 24.05
trace: warning: optionsDocBook is deprecated since 23.11 and will be removed in 24.05
trace: warning: optionsDocBook is deprecated since 23.11 and will be removed in 24.05
[1/83/96 built, 364 copied (3020.9 MiB), 533.7 MiB DL] building SpotifyARM64.dmg:                                  
```

Suggesting that home-manager switch worked, but I probably need to re-run the regular commands with darwin-rebuild switch --flake .#NIXY or somemthing.. for the system build inside the dotfiles local repo again. Not sure why the nix home-manager already went. 

So, I run "rebuild" command, which is a script I wrote in bash as a nix expression to scriptBinary, and it seems to have rebuilt everything.

I can't remember if I specifically mentioned it somewhere, but the system wouldn't do much until I went to System Settings -> General -> About -> Name -> Alex's Macbook Air 2020
and rename it to 'NIXY' because our Flake specifies a hostname of NIXY.

It should be noted the following:
Brave browser doesn't ship a aarch64 package through nixpkgs.. so we've got it installed through homebrew. Don't install it manually.

Running rebuild -r to rebuild icon cache in Launchpad, to see available apps.
Dock shows by default? I thought my darwin-defaults.nix hid that. Also, is there a way to disable wallpaper click on macos Sonoma? It's a Widget thing.

Disable/reduce motion on macos.. Currently, everything is glitchy and ugly otherwise.
Disable hotcorners/remove quicknote corner shortcut mouseover. It's annoying.
Reduce transparency. ## WHY WASN'T THIS DEFAULT? EWW...

Switch default browser to brave. Why isn't this automatic?
Disable "Reopen Windows after Shutdown" option in menubar apple -> Shutdown menu

Sync Brave Browser to my Sync Chain.. Turn on Chrome mem management, and enable extensions "keep it" prompts

Change macos highlight color.

Petty sh*t:
Install Macos Instant View usb display driver by silicon Motion.
Sign into appleid.
Sign out of iMessage 


If 2fa is enabled on github switch to ssh instead of https on linux/macos

1. generate an ssh keypair on your linux/macos
ssh-keygen -t ed25519

2. add the public key to github: profile - settings - ssh keys

3. switch from https to ssh

Check your repo remote:
git remote -v
should show:
origin  https://github.com/aspauldingcode/.dotfiles.git (fetch)
origin  https://github.com/aspauldingcode/.dotfiles.git (push)

Change the remote:
git remote set-url origin git@github.com:aspauildingcode/.dotfiles.git

verify:
git remote -v
should show:
origin  git@github.com:aspauldingcode/.dotfiles.git (fetch)
origin  git@github.com:aspauldingcode/.dotfiles.git (push)

