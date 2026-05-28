# sops-nix Documentation Suite

This is the full multi-file deep dive for `sops-nix` in this repository.

If you are new, read in this order:

1. [`01-architecture.md`](./01-architecture.md)
2. [`02-key-management.md`](./02-key-management.md)
3. [`03-authoring-and-files.md`](./03-authoring-and-files.md)
4. [`04-consumption-patterns.md`](./04-consumption-patterns.md)
5. [`05-templates-and-services.md`](./05-templates-and-services.md)
6. [`06-operations-and-rotation.md`](./06-operations-and-rotation.md)
7. [`07-troubleshooting.md`](./07-troubleshooting.md)
8. [`08-repo-reference.md`](./08-repo-reference.md)

Cross-reference:

- Legacy single-file deep dive: [`../sops-nix.md`](../sops-nix.md)
- Dendritic architecture: [`../dendritic-patterns.md`](../dendritic-patterns.md)
- Den architecture: [`../den.md`](../den.md)

Primary upstream references:

- [Mic92/sops-nix README](https://github.com/Mic92/sops-nix/blob/master/README.md)
- [Mic92/sops-nix repository](https://github.com/Mic92/sops-nix)
- [NixOS module source](https://github.com/Mic92/sops-nix/blob/master/modules/sops/default.nix)
- [Home Manager module source](https://github.com/Mic92/sops-nix/blob/master/modules/home-manager/sops.nix)
- [Native SSH support discussion (PR #779)](https://github.com/Mic92/sops-nix/pull/779)
- [Decryption mismatch discussion (Issue #744)](https://github.com/Mic92/sops-nix/issues/744)
