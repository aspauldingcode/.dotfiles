# 01 - Foundations

## What Dendritic Nix is

Dendritic Nix is a pattern for organizing Nix configurations by **feature** instead of by **target class** or **host folder**.

Traditional split:

- NixOS module in one file
- Home Manager module in another file
- nix-darwin module in yet another file

Dendritic split:

- one feature file can export all relevant class modules together.

## Core problem it solves

As configurations grow, complexity comes from:

- multiple hosts,
- multiple module classes (`nixos`, `darwin`, `homeManager`, etc.),
- nested class evaluation (HM embedded in NixOS/nix-darwin),
- cross-cutting concerns (theme, editor, browser policy, secrets).

Dendritic reduces “where do I edit this?” overhead by making feature ownership explicit.

## The core rule set

From the canonical pattern:

1. every non-entry `.nix` file is a top-level module,
2. each module implements one feature across applicable classes,
3. lower-level modules are merged as option values (typically deferred modules),
4. paths represent feature intent, not class/host assignment.

Source: [mightyiam/dendritic](https://github.com/mightyiam/dendritic).

## Why deferred module merging matters

In `flake-parts`, lower-level class modules are often represented under `flake.modules.*`.

Example style:

```nix
flake.modules.homeManager.dendritic = { ... }: { ... };
flake.modules.darwin.dendritic = { ... }: { ... };
```

Many files can assign to those same option paths. Nix module merging composes them into one final module per class.

That is the key mechanic enabling:

- one feature per file,
- no giant manual import list of every feature in every host.

## What Dendritic is not

- Not a replacement for Nix module semantics.
- Not tied only to flakes (can be adapted with `lib.evalModules`).
- Not only “boilerplate reduction”; it changes architectural ergonomics.

## How it relates to Den

Dendritic pattern: file-level feature composition with merged class modules.

Den framework: function-level/context-aware aspect composition (`den.aspects.*`, `den.hosts.*`) built to solve additional topology and policy complexity.

In this repo:

- core features are mostly classic dendritic (`flake.modules.*.dendritic`),
- host topology is increasingly Den-driven.

See: [`../den.md`](../den.md).
