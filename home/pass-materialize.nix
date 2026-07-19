# SecretSpec key → relative path under $HOME (mode 0600).
# Runtime-only secrets (GH_*, FLAKEHUB_TOKEN, GCLOUD_*) are intentionally absent —
# wrappers / activation read them live via secretspec / pass (ADC rewritten on login).
builtins.fromJSON (builtins.readFile ./pass-materialize.json)
