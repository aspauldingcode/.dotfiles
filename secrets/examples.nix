# Example secrets configuration for sops-nix
# This file demonstrates how to structure secrets for different environments
# and provides templates for common secret types.
# IMPORTANT: This is an example file. Do not put real secrets here.
# Real secrets should be encrypted in the appropriate .yaml files.
# Usage:
# 1. Copy relevant sections to your actual configuration
# 2. Replace example values with references to your encrypted secrets
# 3. Ensure proper file permissions and ownership
# Example structure for different secret types:
{
  # Database credentials
  database = {
    host = "localhost";
    port = 5432;
    username = "myapp";
    # In real config: password = config.sops.secrets.db_password.path;
    password = "/run/secrets/db_password";
  };

  # API keys and tokens
  api = {
    # In real config: github_token = config.sops.secrets.github_token.path;
    github_token = "/run/secrets/github_token";
    # In real config: openai_key = config.sops.secrets.openai_key.path;
    openai_key = "/run/secrets/openai_key";
  };

  # SSH keys and certificates
  ssh = {
    # In real config: private_key = config.sops.secrets.ssh_private_key.path;
    private_key = "/run/secrets/ssh_private_key";
    # In real config: public_key = config.sops.secrets.ssh_public_key.path;
    public_key = "/run/secrets/ssh_public_key";
  };

  # Example of how to use in a module:
  # { config, pkgs, ... }:
  # {
  #   sops.secrets.my_secret = {
  #     sopsFile = ../secrets/production/secrets.yaml;
  #     owner = "myuser";
  #     group = "mygroup";
  #     mode = "0400";
  #   };
  #
  #   services.myservice = {
  #     enable = true;
  #     passwordFile = config.sops.secrets.my_secret.path;
  #   };
  # }
}
# Example Home Manager configuration with secrets
# { config, pkgs, ... }:
# let
#   sopsConfig = import ../sops-nix/sopsConfig.nix {
#     inherit nixpkgs;
#     user = "alex";
#     environment = "development";
#     hostname = "NIXY2";
#   };
# in {
#   imports = [ sopsConfig.hmSopsConfig ];
#
#   # Example program configuration with secrets
#   programs.git = {
#     enable = true;
#     extraConfig = {
#       github.token = config.sops.secrets.github_token.path;
#     };
#   };
#
#   # Example shell aliases using secrets
#   programs.zsh.shellAliases = {
#     # Use command substitution to read secret files
#     "gh-auth" = "gh auth login --with-token < ${config.sops.secrets.github_token.path}";
#   };
# }
# Example utility functions
# let
#   sopsConfig = import ../sops-nix/sopsConfig.nix {
#     inherit nixpkgs;
#     user = "alex";
#     environment = "production";
#     hostname = "NIXY";
#   };
#   utils = sopsConfig.secretUtils;
# in {
#   # Check if secrets exist before using them
#   conditionalService = lib.mkIf (utils.hasSecret "stripe_secret_key") {
#     services.payment-processor = {
#       enable = true;
#       stripeKeyFile = utils.getSecretPath "stripe_secret_key";
#     };
#   };
#
#   # Debug information
#   secretsDebug = {
#     environment = sopsConfig.environmentInfo.environment;
#     secretCount = sopsConfig.environmentInfo.secretCount;
#     availableSecrets = utils.listSecrets;
#   };
# }
