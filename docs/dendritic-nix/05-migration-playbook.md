# 05 - Migration Playbook

Use this when moving from a traditional host/class-split layout to a dendritic layout.

## Starting point (typical)

You may currently have:

- `nixos/hosts/<host>/...`
- `home/<user>/...`
- `darwin/<host>/...`
- duplicated feature logic across class-specific files.

## Migration goals

1. feature files become primary source of truth,
2. host files become identity + selection layer,
3. class-specific exports are merged automatically.

## Step-by-step plan

### Step 1 - Define one merge namespace

Pick stable merge targets:

- `flake.modules.nixos.dendritic`
- `flake.modules.darwin.dendritic`
- `flake.modules.homeManager.dendritic`

### Step 2 - Add module auto-import

Use a top-level module that imports all non-entrypoint feature files.

This repo does that in `modules/default.nix`.

### Step 3 - Migrate one feature end-to-end

Choose one feature (e.g., shell/editor/browser):

1. collect class-specific fragments,
2. place in one feature file,
3. export appropriate class modules.

Validate behavior before moving next feature.

### Step 4 - Slim host files

Hosts should mostly:

- import merged class modules,
- set host identity and feature toggles.

### Step 5 - Standardize option namespace

Create a namespaced toggle/options surface such as `dendritic.*`.

This avoids collisions and clarifies ownership.

### Step 6 - Migrate incrementally

Keep old and new paths side by side temporarily if needed.

A practical coexistence pattern:

- continue consuming merged dendritic module paths,
- optionally add Den aspect mirrors as future-proofing.

## Validation after each migration step

Checklist:

1. evaluation succeeds (`nix flake check` where applicable),
2. host switch succeeds,
3. feature behaves correctly on all intended classes,
4. no hidden dependency on old class-specific file remains.

## Common migration pitfalls

- forgetting to remove old duplicate imports,
- missing option namespace declarations after move,
- overusing `specialArgs` pass-through instead of top-level config sharing,
- assigning too many unique lower-level module names (import explosion).

## “Done” definition

A migration is healthy when:

- adding a new feature means adding one feature file,
- hosts rarely need per-feature import edits,
- cross-class feature behavior lives in one place,
- contributors can locate ownership quickly.
