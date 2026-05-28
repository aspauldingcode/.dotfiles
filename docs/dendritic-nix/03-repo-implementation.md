# 03 - Implementation in This Repository

This chapter maps the dendritic pattern to concrete files in this repo.

## High-level structure

- `flake.nix`
  - flake inputs
  - top-level flake-parts evaluation
  - imports `./modules`
- `modules/default.nix`
  - auto-imports all feature modules
- `modules/**/*.nix`
  - feature-centric module files exporting class modules
- `hosts/**`
  - identity/topology/host-specific glue and toggles

## Main merged class outputs

The dominant merge targets are:

- `flake.modules.homeManager.dendritic`
- `flake.modules.darwin.dendritic`
- `flake.modules.nixos.dendritic`

Most feature files contribute to one or more of these.

## Real examples in this repo

### Dock composition

- `modules/dock.nix` defines `dendritic.dock.apps` option and base entries.
- app modules append entries with `lib.mkOrder`.

This is a classic dendritic merge: distributed feature ownership + deterministic final order.

### Brave as multi-class feature

- file: `modules/apps/brave.nix`
- contributes HM + Darwin modules
- contains app settings, activation scripting, SOPS secret integration, dock registration

This demonstrates “single feature file spanning multiple classes”.

### Python feature across classes

- file: `modules/python.nix`
- contributes NixOS + Darwin + HM modules under one feature namespace

### Shared secrets feature

- file: `modules/secrets.nix`
- exports all three classes and centralizes SOPS defaults

## Host wiring examples

### Darwin host

`hosts/darwin/mba/default.nix` imports:

- `inputs.self.modules.darwin.dendritic`
- `inputs.self.modules.homeManager.dendritic` (inside HM user block)

and toggles feature options under `dendritic.*`.

### NixOS host

`hosts/nixos/*/default.nix` follows similar pattern:

- imports merged `nixos` and embedded `homeManager` dendritic modules
- sets host-specific values while keeping features in modules.

## Den interop in this repo

Dendritic modules remain core feature layer.

Den currently owns host topology in:

- `modules/host-topology-den.nix`
- `den-aspects/styling.nix`

There are dual-export patterns where feature modules also expose a Den aspect for future migration paths.

## Practical takeaway

In this repo, Dendritic Nix is not theoretical - it is the default module authoring model:

- add new feature file,
- export relevant class modules,
- consume automatically through merged class imports already used by hosts.
