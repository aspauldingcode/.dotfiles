# 06 - Anti-Patterns

These are the most common ways teams accidentally defeat dendritic benefits.

## 1) `specialArgs` as cross-file dependency bus

Symptom:

- values are passed through `specialArgs`/`extraSpecialArgs` chains to make modules work.

Why this hurts:

- hidden coupling,
- harder refactors,
- module portability drops.

Preferred:

- expose shared values in top-level module `config` and consume from there.

Canonical warning source:

- [mightyiam/dendritic anti-patterns](https://github.com/mightyiam/dendritic)

## 2) Proliferation of named lower-level modules

Symptom:

- one unique `flake.modules.<class>.<featureName>` per feature,
- hosts import long lists of these names.

Why this hurts:

- host imports become maintenance burden,
- adding/removing features requires host file churn.

Preferred:

- merge most features under one stable name per class (e.g. `.dendritic`).

## 3) Class-centric file layout relabeled as dendritic

Symptom:

- still mostly `nixos/*.nix`, `home-manager/*.nix`, `darwin/*.nix`,
- feature intent scattered.

Why this hurts:

- same old navigation problem remains.

Preferred:

- files named/grouped by feature concern.

## 4) Feature file that owns too many unrelated concerns

Symptom:

- huge “god feature” module with unrelated domains.

Why this hurts:

- reviewability and ownership collapse.

Preferred:

- split by cohesive feature boundary; use internal helper files if needed.

## 5) Hardcoding host-specific values inside reusable feature modules

Symptom:

- feature module embeds one host’s identity details.

Why this hurts:

- feature cannot be reused cleanly.

Preferred:

- keep identity/topology in host layer; keep feature logic in feature module.

## 6) Manual import lists for all features

Symptom:

- adding a feature requires touching multiple import files.

Why this hurts:

- brittle and easy to forget.

Preferred:

- auto-import non-entrypoint feature files.

## 7) No clear namespace for feature options

Symptom:

- options spread into generic/global namespaces.

Why this hurts:

- collisions and unclear ownership.

Preferred:

- use `dendritic.*` (or another explicit feature namespace).

## Quick anti-pattern detector

If a simple feature change requires editing:

- one class file per platform,
- plus host import lists,
- plus ad-hoc arg passing,

you are drifting away from dendritic ergonomics.
