{
  # The GitHub CLI (`gh`) authenticates against api.github.com via,
  # in priority order: `GH_TOKEN` env var → `GITHUB_TOKEN` env var →
  # OS keychain entry seeded by `gh auth login` → `oauth_token` in
  # `~/.config/gh/hosts.yml`. The interactive `gh auth login` flow is
  # great on a single machine but fights declarative dotfiles (the
  # token lives in OS-specific keychains, can't be replayed onto a
  # fresh host, and silently rotates outside Git). The env-var
  # override path lets us source the token from our sops-nix
  # secrets store so every host built from this flake gets the
  # same identity without any post-bootstrap manual steps.
  #
  # Same posture as `chatgpt-cli`: wrap `pkgs.gh` in a thin
  # `writeShellScriptBin` that exports `GH_TOKEN` only for the
  # `gh` process. We refuse to set `GH_TOKEN` globally (every
  # shell child — terminals, LSP, formatters, lazygit's subshells —
  # would inherit it), and we refuse to symlink the plaintext
  # secret into `~/.config/gh/hosts.yml` (a world-readable home
  # location).
  #
  # Self-contained secret declaration: `sops.secrets.gh_token = {}`
  # is set-merged across consumers, so other modules can ALSO
  # declare it without conflict. Update the encrypted value via
  # `sops edit secrets/secrets.yaml`.
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      config,
      ...
    }:
    let
      tokenPath = config.sops.secrets.gh_token.path;
      gh = pkgs.writeShellScriptBin "gh" ''
        # Fall through silently if the sops secret hasn't been
        # materialised yet (fresh bootstrap, sops-nix launchd agent
        # failed, etc.) — `gh` will print its own clearer
        # "not logged in" diagnostic than a `cat: ... No such file`
        # error would.
        if [ -r "${tokenPath}" ]; then
          GH_TOKEN="$(cat "${tokenPath}")"
          export GH_TOKEN
        fi
        exec ${pkgs.gh}/bin/gh "$@"
      '';
    in
    {
      sops.secrets.gh_token = { };
      # Only the wrapper goes into PATH; it Nix-references the real
      # `pkgs.gh` via the `exec` line, so the underlying binary is
      # still pulled into the closure but never shadowed by the
      # wrapper.
      home.packages = [ gh ];
    };
}
