# SecretSpec key → relative path under $HOME (mode 0600).
# Runtime-only secrets (GH_*, FLAKEHUB_TOKEN) are intentionally absent —
# wrappers read them live via secretspec / pass.
builtins.fromJSON (builtins.readFile ./pass-materialize.json)
