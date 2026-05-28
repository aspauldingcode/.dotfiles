# 04 - Real Dendritic Nix Examples

This chapter answers the practical question: “show me real dendritic repos and what they do.”

## A) Real examples in this repository

### 1) Browser feature across classes

- File: `modules/apps/brave.nix`
- Shows:
  - HM and Darwin class exports in one feature file
  - SOPS secret consumption
  - activation scripting
  - dock contribution

Why it is dendritic:

- feature-local ownership, not split by class directories.

### 2) Dock as merge surface

- Files:
  - `modules/dock.nix` (base option + defaults)
  - `modules/apps/*.nix` (ordered app contributions)

Why it is dendritic:

- multiple features merge into one shared option (`dendritic.dock.apps`) while staying independently owned.

### 3) Cross-platform feature file

- File: `modules/python.nix`
- Shows one feature emitting NixOS, Darwin, and HM behavior.

### 4) Shared secrets feature

- File: `modules/secrets.nix`
- Shows one feature wiring the same capability across all three classes.

### 5) Theme stack with Den bridge

- File: `den-aspects/styling.nix`
- Shows:
  - Den aspect composition
  - HM mirror export to dendritic merge target for backward compatibility

Why this matters:

- demonstrates real migration coexistence between classic dendritic exports and Den aspects.

## B) Canonical upstream example (annotated template)

Upstream repo includes a minimal annotated sample:

- [mightyiam/dendritic/example](https://github.com/mightyiam/dendritic/tree/main/example)

Representative files:

- `example/modules/nixos.nix` - declares NixOS config options as deferred modules
- `example/modules/shell.nix` - feature module exporting multiple classes
- `example/modules/systems.nix` - systems declaration

This example is intentionally small and incomplete by design; it teaches mechanics, not production topology.

## C) Public real-world repos cited by upstream

From [mightyiam/dendritic README](https://github.com/mightyiam/dendritic):

- [mightyiam/infra](https://github.com/mightyiam/infra)
- [vic/vix](https://github.com/vic/vix)
- [drupol/nixos-x260](https://github.com/drupol/nixos-x260)
- [GaetanLepage/nix-config](https://github.com/GaetanLepage/nix-config)
- [bivsk/nix-iv](https://github.com/bivsk/nix-iv)

These are useful to study larger production patterns:

- feature slicing strategies,
- option namespacing discipline,
- host wiring styles,
- cross-class sharing and constraints.

## D) Dendritic + Den ecosystem examples

If you want deeper aspect-oriented extensions:

- [denful/den](https://github.com/denful/den)
- [dendrix.denful.dev](https://dendrix.denful.dev/)

These show how teams evolve from classic dendritic merges into context-driven aspect pipelines while keeping feature-centric design.

## How to evaluate if a repo is truly dendritic

Heuristics:

1. Most non-entry files are top-level modules.
2. Files are feature-centric, not class-centric.
3. Lower-level class modules are merged under stable names.
4. Host files are relatively slim and import merged module sets.
5. Feature changes usually touch one feature file, not three class-specific files.
