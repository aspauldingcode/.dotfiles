# 02 - Module Mechanics

This chapter explains exactly how dendritic composition works in practice.

## Top-level auto-import

In this repo, `modules/default.nix` auto-imports all non-private, non-entrypoint `.nix` files under `modules/`.

That means adding `modules/apps/new-feature.nix` is enough for participation in top-level evaluation.

## Class exports

A dendritic feature file typically exports one or more of:

- `flake.modules.nixos.dendritic`
- `flake.modules.darwin.dendritic`
- `flake.modules.homeManager.dendritic`

Example pattern:

```nix
{
  flake.modules.homeManager.dendritic = hmModule;
  flake.modules.darwin.dendritic = darwinModule;
}
```

Multiple files assigning these keys are merged by module semantics.

## Host consumption

Hosts consume class-level merged modules once:

```nix
imports = [
  inputs.self.modules.darwin.dendritic
];
```

Embedded HM users consume:

```nix
imports = [
  inputs.self.modules.homeManager.dendritic
];
```

No per-feature imports required in host files.

## Option namespace strategy

Feature options are namespaced under `dendritic.*`:

```nix
options.dendritic.apps.ghostty.enable = ...
```

Benefits:

- avoids collisions with upstream module option names,
- gives hosts a clean feature toggle surface.

## Cross-file composition patterns

### Ordered composition

Use `lib.mkOrder` when composing ordered lists across features (e.g. Dock apps).

### Shared let-bound modules

For dual export paths, define module body once and assign to multiple targets.

Example from this repo:

- feature module is exported both to `flake.modules.*.dendritic` and `den.aspects.<feature>`.

### Class-selective exporting

Only export classes where feature applies:

- HM-only feature: export only `homeManager` class.
- Darwin-only feature: export only `darwin` class.

## Decomposing a feature safely

When splitting a large feature file:

1. keep option namespace stable (`dendritic.<feature>.*`),
2. split internals into private helpers (`_name.nix`) when needed,
3. keep final class exports predictable.

Auto-import excludes `_*.nix` helpers in this repo, enabling internal refactors without changing top-level module graph.

## Evaluating behavior

When behavior feels surprising, check:

1. did module file get auto-imported?
2. which class exports are present?
3. is host importing the correct merged class module?
4. are option merges (`mkDefault`/`mkForce`/`mkOrder`) behaving as expected?
