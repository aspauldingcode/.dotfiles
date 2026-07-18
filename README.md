# Alex Spaulding's Dotfiles (Dendritic Nix)

Personal, declarative system configuration built by **Alex Spaulding (aspauldingcode)** using Nix Flakes.

<!-- fleet-status:start -->

## Fleet

[![mba](https://img.shields.io/badge/mba-online-brightgreen)](docs/fleet-status.md) [![sliceanddice](https://img.shields.io/badge/sliceanddice-stale-yellow)](docs/fleet-status.md)

Host presence via private heartbeats (no public IPs). Badges: online ≤30m · stale ≤24h · else offline. See [docs/fleet-status.md](docs/fleet-status.md).

<!-- fleet-status:end -->

## Clone Location

Following the [dendritic pattern](https://github.com/mightyiam/dendritic), this repository should be cloned to the system configuration directory for your platform. The config is system-wide and shared across all users — editing requires admin privileges.

| Platform               | Path                         |
| ---------------------- | ---------------------------- |
| **NixOS**              | `/etc/nixos/`                |
| **macOS (nix-darwin)** | `/etc/nix-darwin/.dotfiles/` |

```bash
# macOS
sudo git clone git@github.com:aspauldingcode/.dotfiles.git /etc/nix-darwin/.dotfiles

# NixOS
sudo git clone git@github.com:aspauldingcode/.dotfiles.git /etc/nixos
```

## Quick Install (macOS)

You can bootstrap this dotfiles configuration directly on a fresh macOS machine with Nix installed by running a single command.

The install script will automatically clone the repository to `/etc/nix-darwin/.dotfiles` (or `/etc/nixos` on NixOS) and apply the system configuration. We use the tarball link so it works even if your brand-new Mac doesn't have `git` installed yet:

```bash
nix run github:aspauldingcode/.dotfiles#install
```

_(Alternatively, if you have `git` installed and prefer to authenticate over SSH, you can run `nix run git+ssh://git@github.com/aspauldingcode/.dotfiles.git#install`)_

## Daily Usage

Once the system is installed, you can apply changes to your configuration using the `nh` (Nix Helper) CLI. The `NH_FLAKE` environment variable is automatically configured to point to the correct system directory.

```bash
# Navigate to your config
cd /etc/nix-darwin/.dotfiles   # macOS
cd /etc/nixos        # NixOS

# Standard rebuild (uses the NH_FLAKE variable we configured)
nh darwin switch

# Manual rebuild (if variable is not yet active or you are on a new host)
nh darwin switch /etc/nix-darwin/.dotfiles -H mba
nh os switch /etc/nixos -H my-nixos-host
```

### Pro Tips for `nh`

- Use **`--ask`** to see a diff of what will change before confirming.
- Use **`--update`** to update all your flake inputs (packages) to their latest versions.
- The `NH_FLAKE` variable is set to `/etc/nix-darwin/.dotfiles#mba` (macOS) or `/etc/nixos` (NixOS), so `nh` always knows which host to build by default.

## Documentation

- **[Pass + SecretSpec sync](docs/pass-secretspec.md)** — How the private password-store, ntfy peer wake, and SecretSpec work; how to replicate with your own vault (no one else’s secrets).
- **[Dendritic Wi-Fi](docs/wifi.md)** — Declarative Bubbles (and friends) via pass PSK on macOS + NixOS/iwd.
- **[Dendritic Nix Documentation Suite](docs/dendritic-nix/README.md)** — Full multi-file deep dive: foundations, mechanics, repo implementation, real examples, migration, and anti-patterns.
- **[Dendritic Nix: Patterns, Den, and Dendrix](docs/dendritic-patterns.md)** — Single-file overview of the pattern and ecosystem.
- **[Den — Deep Reference](docs/den.md)** — Detailed documentation on Den: aspects, hosts, policies, classes, pipeline, and how this flake uses them.
- **[sops-nix Documentation Suite](docs/sops-nix/README.md)** — Full multi-file reference for sops-nix: architecture, key management, authoring, templates, operations, and troubleshooting.
- **[Zsh Plugins & Shell Extensions](docs/zsh-plugins.md)** — Full reference of all curated zsh plugins, CLI tools, and Nix-specific integrations.
- **[Tmux Master Guide](docs/tmux.md)** — Learn how to use your optimized terminal multiplexer with interactive hints.

## Uninstallation

If you ever wish to remove `nix-darwin` and revert your system changes without removing Nix itself, run the following command:

```bash
nix run github:aspauldingcode/.dotfiles#uninstall
```

This will safely present a terminal UI to confirm, uninstall `nix-darwin`, delete all system generations, and garbage collect to free up space.
