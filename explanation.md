# Simple Explanation: Shared Config Across NixOS, macOS, and Generic Linux

This repo provides a single, shared configuration you can apply to thousands of machines without per-host files in the repo. Hardware and host identity are kept host-local where needed, while the repo stays generic and pure.

## Goals
- One shared Home Manager configuration applied everywhere.
- NixOS and nix-darwin manage system settings; non‑NixOS Linux uses HM‑only.
- Multi‑host support without flooding the repo with host folders.

## Repo Layout
- `flake.nix`: Core logic, inputs/outputs, shared HM modules, NixOS/Darwin wiring.
- `flake.lock`: Pinned inputs for reproducibility.
- `scripts/regenerate-hardware.sh`: Generates `hardware/<host>.nix` + `hardware/<host>.system` on NixOS hosts.
- `hardware/` (optional): Host hardware files created on NixOS hosts. The repo works even without it.

## Flake Inputs
- `nixpkgs`, `nixpkgs-darwin`, `flake-utils`
- `nix-darwin` (macOS system management)
- `home-manager` (shared user config)
- `sops-nix` (placeholder for secrets)
- `determinate-nix` (recommended Nix installer on macOS/Linux)

## Outputs Overview
- `nixosConfigurations`: Built dynamically from `hardware/*.nix` + `*.system`.
  - Each NixOS config includes a minimal base module (`system.stateVersion`, admin user) and the shared HM for user `admin`.
- `darwinConfigurations.myMac`: nix-darwin config with the shared HM for user `admin`.
- `homeConfigurations.admin-linux`: HM‑only profile for generic Linux (Fedora/Ubuntu), using the same shared HM modules.
- `packages.<system>.default`: Example environment derivation.

## Shared Home Manager Modules
The flake defines `hmSharedModules` once and uses it on all platforms:
- Enable: `xdg`, `zsh`, `git`, `fzf`, `direnv` with `nix-direnv`, `starship`.
- Packages: `git`, `curl`, `wget`, `ripgrep`, `fd`, `bat`, `tree`, `htop`, `neovim`, `podman`, `qemu`.
- `home.stateVersion = "24.11"` is set inside HM modules when applied via NixOS/Darwin; for Linux HM‑only, it’s set in the HM output.

## NixOS (System + HM)
Multi‑host support is simple and pure:
1. On the NixOS host, run:
   - `./scripts/regenerate-hardware.sh`
   - This writes `hardware/<host>.nix` and `hardware/<host>.system` in the repo.
2. Push changes (optional, if you want to keep hardware in the repo):
   - `git add hardware && git commit -m "add <host> hardware" && git push origin dev`
3. Switch the host:
   - `sudo nixos-rebuild switch --flake github:aspauldingcode/.dotfiles?ref=dev#<host>`

Notes:
- Each NixOS config automatically includes a minimal base module setting `system.stateVersion` and creating `users.users.admin` with `wheel` and `sudo` enabled.
- The shared HM user (`admin`) is applied via `home-manager.nixosModules.home-manager` inside every NixOS config.

## macOS (System + HM)
Use nix-darwin for system, with shared HM for the same `admin` user:
- `darwin-rebuild switch --flake github:aspauldingcode/.dotfiles?ref=dev#myMac`
- HM home directory on macOS: `/Users/admin`.
- The flake disables Nix management inside darwin and favors Determinate Nix.

## Generic Linux (HM‑only)
For Fedora/Ubuntu or other non‑NixOS Linux, use the HM‑only output:
1. Install Nix:
   - `curl -fsSL https://get.determinate.systems/nix | sh -s -- install`
2. Ensure user `admin` exists with home `/home/admin` and sudo per distro policy.
3. Switch HM:
   - `nix run nixpkgs#home-manager -- switch --flake github:aspauldingcode/.dotfiles?ref=dev#admin-linux`
4. Test only (no activation):
   - `nix build github:aspauldingcode/.dotfiles?ref=dev#homeConfigurations.admin-linux.activationPackage`

## Building and Testing on Non‑NixOS
You can validate NixOS configs from Fedora/Ubuntu:
- Create a stub:
  - `mkdir -p hardware`
  - `printf '{ ... }: { system.stateVersion = "24.11"; }\n' > hardware/devtest.nix`
  - `echo x86_64-linux > hardware/devtest.system`
- Build the closure:
  - `nix build github:aspauldingcode/.dotfiles?ref=dev#nixosConfigurations.devtest.config.system.build.toplevel`
- Build and run a VM:
  - `nix build github:aspauldingcode/.dotfiles?ref=dev#nixosConfigurations.devtest.config.system.build.vm`
  - `./result/bin/run-devtest-vm`

## Fleet‑Scale Options (Avoid Repo Bloat)
If you have thousands of devices, you don’t need per‑host files in the repo:

1) Host‑local flake input overrides (recommended)
- Keep the repo generic; inject hardware and identity from the host at build time.
- Command pattern:
  - `sudo nixos-rebuild switch --flake github:aspauldingcode/.dotfiles?ref=dev#core \
    --override-input host-hw path:/etc/nixos/hardware-configuration.nix \
    --override-input host-params path:/etc/nixos/host.json`
- `host.json` example:
  - `{ "system": "x86_64-linux", "hostname": "esmeralda", "uuids": { "/": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee", "/boot": "1234-ABCD" } }`

2) Standardize disk labels or use Disko (most pure)
- Reference `fileSystems` by label (e.g., `/dev/disk/by-label/nixos-root`) or declare disks via `disko`.
- No per‑host hardware differences; a single config fits all machines with the same layout.

3) Parameterized hardware function (`mkHost`)
- Define a function that takes UUIDs/labels + hostname and returns a module:
  - `mkHost { hostname = "esmeralda"; uuids = { "/" = "..."; "/boot" = "..."; }; }`
- Feed it via `host.json` on each machine (override input), keep the repo generic.

Specializations
- Useful for a handful of alternative profiles; not ideal for thousands.

## Commands Cheat Sheet
- NixOS switch: `sudo nixos-rebuild switch --flake github:aspauldingcode/.dotfiles?ref=dev#<host>`
- macOS switch: `darwin-rebuild switch --flake github:aspauldingcode/.dotfiles?ref=dev#myMac`
- Linux HM switch: `nix run nixpkgs#home-manager -- switch --flake github:aspauldingcode/.dotfiles?ref=dev#admin-linux`
- Build NixOS VM: `nix build github:aspauldingcode/.dotfiles?ref=dev#nixosConfigurations.<host>.config.system.build.vm`

## Why It’s Simple
- Shared HM is defined once and reused everywhere.
- NixOS/Darwin carry system responsibilities; Linux HM‑only focuses on user environment.
- Multi‑host hardware handled via `hardware/*.nix` + `*.system` or host‑local inputs, keeping the repo clean.

## Notes
- HM user is `admin` by default; paths are `/home/admin` (Linux) and `/Users/admin` (macOS).
- You can parameterize the username per host while keeping the same shared HM modules.
- `sops-nix` is included for future secrets management; currently unused.
- `packages.default` is a small example derivation; not required for usage.

## Contributing
- Use the `dev` branch for staging; reference flake URLs with `?ref=dev`.
- CI (optional): add `nix flake check` on pushes to `dev` before merging.