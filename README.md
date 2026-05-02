# Alex Spaulding's Dotfiles (Dendritic Nix)

Personal, declarative system configuration built by **Alex Spaulding (aspauldingcode)** using Nix Flakes.

## Quick Install (macOS)

You can bootstrap this dotfiles configuration directly on a fresh macOS machine with Nix installed by running a single command. 

To automatically clone the repository to `~/.dotfiles` and apply the system configuration using `nh darwin switch`, simply copy and paste the following line into your terminal. We use the tarball link so it works even if your brand-new Mac doesn't have `git` installed yet:

```bash
nix run github:aspauldingcode/.dotfiles#install
```

*(Alternatively, if you have `git` installed and prefer to authenticate over SSH, you can run `nix run git+ssh://git@github.com/aspauldingcode/.dotfiles.git#install`)*

## Daily Usage

Once the system is installed, you can apply changes to your configuration (located in `~/.dotfiles`) using the `nh` (Nix Helper) CLI. This setup uses a `FLAKE` environment variable to automate path discovery.

```bash
# Navigate to your dotfiles
cd ~/.dotfiles

# Standard rebuild (uses the FLAKE variable we configured)
nh darwin switch

# Manual rebuild (if variable is not yet active or you are on a new host)
nh darwin switch . -H mba
nh os switch . -H my-nixos-host
```

### Pro Tips for `nh`
- Use **`--ask`** to see a diff of what will change before confirming.
- Use **`--update`** to update all your flake inputs (packages) to their latest versions.
- The `FLAKE` variable in your shell config is set to `~/.dotfiles#mba`, so `nh` always knows which host to build by default.

## Uninstallation

If you ever wish to remove `nix-darwin` and revert your system changes without removing Nix itself, run the following command:

```bash
nix run github:aspauldingcode/.dotfiles#uninstall
```

This will safely present a terminal UI to confirm, uninstall `nix-darwin`, delete all system generations, and garbage collect to free up space.
