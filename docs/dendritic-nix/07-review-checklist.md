# 07 - Review Checklist

Use this checklist in PR reviews to keep dendritic architecture healthy.

## File structure checks

- [ ] New feature is implemented in a feature-centric file path.
- [ ] File is auto-importable (non-entrypoint, not private helper unless intended).
- [ ] No unnecessary class-split duplicate files were introduced.

## Module export checks

- [ ] Feature exports only relevant class modules.
- [ ] Exports target stable merge keys (`flake.modules.*.dendritic`) unless there is a clear exception.
- [ ] Option declarations and usage stay within namespace conventions (`dendritic.*`).

## Host-layer checks

- [ ] Host files are mostly topology/identity/toggles, not feature internals.
- [ ] Host files import merged class modules (not long per-feature import lists).

## Merge behavior checks

- [ ] `mkDefault` / `mkForce` / `mkOrder` usage is intentional and documented when non-obvious.
- [ ] Ordered aggregations (like lists) are deterministic when feature composition matters.

## Dependency and coupling checks

- [ ] No new fragile `specialArgs` pass-through chains were introduced.
- [ ] Cross-file value sharing uses top-level config/options where possible.

## Real-world quality checks

- [ ] Feature behavior was validated on each applicable class (Darwin/NixOS/HM).
- [ ] Migration coexistence paths are explicit when both dendritic and Den exports are present.
- [ ] Docs were updated if architecture or conventions changed.

## “Looks dendritic” smell test

- [ ] Could a new contributor discover “where this feature lives” in one or two jumps?
- [ ] Does adding another host require little/no feature-module churn?
- [ ] Would removing one feature be localized instead of invasive?

If all three are “yes,” architecture is usually healthy.
