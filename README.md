# Alex Spaulding's Dotfiles (Dendritic Nix)

Personal, declarative system configuration built by **Alex Spaulding (aspauldingcode)** using Nix Flakes.

## Clone Location

Following the [dendritic pattern](https://github.com/mightyiam/dendritic), this repository should be cloned to the system configuration directory for your platform. The config is system-wide and shared across all users — editing requires admin privileges.

| Platform | Path |
|---|---|
| **NixOS** | `/etc/nixos/` |
| **macOS (nix-darwin)** | `/etc/nix-darwin/` |

```bash
# macOS
sudo git clone git@github.com:aspauldingcode/.dotfiles.git /etc/nix-darwin

# NixOS
sudo git clone git@github.com:aspauldingcode/.dotfiles.git /etc/nixos
```

## Quick Install (macOS)

You can bootstrap this dotfiles configuration directly on a fresh macOS machine with Nix installed by running a single command.

The install script will automatically clone the repository to `/etc/nix-darwin` (or `/etc/nixos` on NixOS) and apply the system configuration. We use the tarball link so it works even if your brand-new Mac doesn't have `git` installed yet:

```bash
nix run github:aspauldingcode/.dotfiles#install
```

*(Alternatively, if you have `git` installed and prefer to authenticate over SSH, you can run `nix run git+ssh://git@github.com/aspauldingcode/.dotfiles.git#install`)*

## Daily Usage

Once the system is installed, you can apply changes to your configuration using the `nh` (Nix Helper) CLI. The `NH_FLAKE` environment variable is automatically configured to point to the correct system directory.

```bash
# Navigate to your config
cd /etc/nix-darwin   # macOS
cd /etc/nixos        # NixOS

# Standard rebuild (uses the NH_FLAKE variable we configured)
nh darwin switch

# Manual rebuild (if variable is not yet active or you are on a new host)
nh darwin switch /etc/nix-darwin -H mba
nh os switch /etc/nixos -H my-nixos-host
```

### Pro Tips for `nh`
- Use **`--ask`** to see a diff of what will change before confirming.
- Use **`--update`** to update all your flake inputs (packages) to their latest versions.
- The `NH_FLAKE` variable is set to `/etc/nix-darwin#mba` (macOS) or `/etc/nixos` (NixOS), so `nh` always knows which host to build by default.

## Uninstallation

If you ever wish to remove `nix-darwin` and revert your system changes without removing Nix itself, run the following command:

```bash
nix run github:aspauldingcode/.dotfiles#uninstall
```

This will safely present a terminal UI to confirm, uninstall `nix-darwin`, delete all system generations, and garbage collect to free up space.
