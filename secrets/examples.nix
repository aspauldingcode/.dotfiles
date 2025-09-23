# sops-nix Examples
# Two ways to reference secrets:
# 1. config.sops.secrets.name.path → file path ("/run/secrets/name")
# 2. config.sops.placeholder."name" → actual secret value
{
  # Basic secret configuration
  sops.secrets.my_secret = {
    sopsFile = ../secrets/development/secrets.yaml;
    owner = "alex";
    mode = "0400";
  };

  # File path usage (.path)
  services.myservice.passwordFile = config.sops.secrets.my_secret.path;
  programs.git.extraConfig.github.token = config.sops.secrets.github_token.path;

  # Direct value usage (.placeholder)
  environment.variables.GITHUB_TOKEN = config.sops.placeholder."github_token";
  home.sessionVariables.OPENAI_API_KEY = config.sops.placeholder."openai_api_key";

  # Shell command with file
  programs.zsh.shellAliases."gh-auth" =
    "gh auth login --with-token < ${config.sops.secrets.github_token.path}";
}
