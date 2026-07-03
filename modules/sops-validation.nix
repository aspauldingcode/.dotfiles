# Dendritic feature: `nix flake check` validates every sops-encrypted
# file in the repo is structurally a valid sops document.
#
# Why this exists: nothing currently catches "I accidentally committed a
# plaintext PEM under a .sops name" or "I forgot `sops updatekeys` after
# a recipient change and broke the MAC". Per-secret runtime decryption
# would catch it, but only at HM activation time on every machine, which
# is too late. This check runs at flake-eval time and is cheap.
#
# The check is structural, not cryptographic:
#   - it does NOT decrypt (no key material needed in CI),
#   - it asserts each file has a top-level `sops` metadata block with
#     `mac`, `lastmodified`, and `version` fields.
#
# Add new sops-encrypted files to `sopsFiles` below as the surface grows.
{
  perSystem =
    { pkgs, lib, ... }:
    let
      sopsFiles = [
        ../secrets/secrets.yaml
        ../secrets/sliceanddice-secrets.yaml
      ];

      # Interpolate each path individually so Nix string-context is
      # preserved per file (each becomes a proper store-path reference
      # in the resulting derivation). `toString` on a list of paths
      # would flatten them into a context-free string and produce a
      # noisy `builtins.derivation … without a proper context` warning.
      sopsFilesArgs = lib.concatMapStringsSep " " (p: "${p}") sopsFiles;

      checker =
        pkgs.writers.writePython3 "sops-parse-check"
          {
            libraries = [ pkgs.python3Packages.pyyaml ];
            flakeIgnore = [
              "E501" # line length: the path arg list is naturally long
              "W503" # line break before binary operator (no longer recommended)
            ];
          }
          ''
            import json
            import sys
            from pathlib import Path

            import yaml


            REQUIRED_METADATA_KEYS = {"mac", "lastmodified", "version"}


            def load_sops(path: Path):
                """Parse a sops file as either JSON envelope or YAML envelope."""
                text = path.read_text()
                stripped = text.lstrip()
                if stripped.startswith("{"):
                    return json.loads(text)
                return yaml.safe_load(text)


            def validate(path: Path) -> str | None:
                try:
                    doc = load_sops(path)
                except Exception as exc:
                    return f"failed to parse as JSON or YAML: {exc}"

                if not isinstance(doc, dict):
                    return f"top-level is {type(doc).__name__}, expected mapping"

                sops_meta = doc.get("sops")
                if sops_meta is None:
                    return "missing top-level `sops` metadata block (file is not sops-encrypted?)"
                if not isinstance(sops_meta, dict):
                    return f"`sops` block is {type(sops_meta).__name__}, expected mapping"

                missing = REQUIRED_METADATA_KEYS - sops_meta.keys()
                if missing:
                    return f"`sops` block missing required keys: {sorted(missing)}"

                return None


            def main() -> int:
                files = [Path(p) for p in sys.argv[1:]]
                failures = []
                for f in files:
                    if not f.exists():
                        failures.append(f"{f}: file does not exist")
                        continue
                    err = validate(f)
                    if err:
                        failures.append(f"{f}: {err}")
                    else:
                        print(f"ok: {f}")

                if failures:
                    print("\nsops-files-parse FAILED:", file=sys.stderr)
                    for line in failures:
                        print(f"  - {line}", file=sys.stderr)
                    return 1
                return 0


            sys.exit(main())
          '';
    in
    {
      checks.sops-files-parse = pkgs.runCommand "sops-files-parse" { } ''
        ${checker} ${sopsFilesArgs}
        touch $out
      '';
    };
}
