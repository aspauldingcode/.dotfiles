{
  # `j178/chatgpt` (nixpkgs: `chatgpt-cli`) is a TUI ChatGPT client. It
  # reads its OpenAI key from either an `OPENAI_API_KEY` env var or
  # `~/.config/chatgpt/config.json`. We refuse to symlink the
  # plaintext sops secret into a public config path, and we refuse to
  # export `OPENAI_API_KEY` globally (every spawned process would
  # inherit it). Instead we ship a thin `writeShellScriptBin` wrapper
  # that lifts the key from the sops-nix runtime path *only* for the
  # `chatgpt` process, then `exec`s the upstream binary.
  #
  # The secret is declared here so this module is self-contained —
  # `sops.secrets.openai_api_key = { }` is set-merged across every
  # consumer (`modules/editor.nix` declares the same value for the
  # Nixvim/CodeCompanion adapter), so nothing breaks if one of the
  # consumers is later removed.
  flake.modules.homeManager.dendritic =
    { pkgs, config, ... }:
    let
      keyPath = config.sops.secrets.openai_api_key.path;
      chatgpt = pkgs.writeShellScriptBin "chatgpt" ''
        # If the sops secret hasn't been materialised yet (e.g. the
        # user is mid-bootstrap or the sops-nix launchd agent failed),
        # fall through with whatever `OPENAI_API_KEY` is already in
        # the environment — j178/chatgpt will surface its own
        # "unauthorized" error, which is a clearer diagnostic than
        # `cat: <path>: No such file or directory` would be.
        if [ -r "${keyPath}" ]; then
          OPENAI_API_KEY="$(cat "${keyPath}")"
          export OPENAI_API_KEY
        fi
        exec ${pkgs.chatgpt-cli}/bin/chatgpt "$@"
      '';
    in
    {
      sops.secrets.openai_api_key = { };
      home.packages = [ chatgpt ];
    };
}
