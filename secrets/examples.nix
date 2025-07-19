# Usage examples for the new sops-nix configuration

{ config, pkgs, ... }:
let
  # Import the sops configuration
  sopsConfig = import ../sops-nix/sopsConfig.nix {
    inherit nixpkgs;
    user = "alex";
    environment = "development"; # Change to "production" for production
    hostname = config.networking.hostName or "unknown";
  };
in {
  # For NixOS configurations
  imports = [ sopsConfig.nixosSopsConfig ];
  
  # Example service using secrets
  services.myapp = {
    enable = true;
    apiKeyFile = config.sops.secrets.anthropic_api_key.path;
    databaseUrl = config.sops.secrets.database_url.path;
  };
  
  # Example environment variables
  environment.variables = {
    # Don't expose secrets directly, use files instead
    API_KEY_FILE = config.sops.secrets.anthropic_api_key.path;
  };
  
  # Example systemd service with secrets
  systemd.services.my-service = {
    serviceConfig = {
      EnvironmentFile = config.sops.secrets.app_env.path;
      LoadCredential = [
        "api-key:${config.sops.secrets.anthropic_api_key.path}"
        "db-password:${config.sops.secrets.database_password.path}"
      ];
    };
  };
}

# For Home Manager configurations
{ config, pkgs, ... }:
let
  sopsConfig = import ../sops-nix/sopsConfig.nix {
    inherit nixpkgs;
    user = "alex";
    environment = "development";
    hostname = "NIXY2";
  };
in {
  imports = [ sopsConfig.hmSopsConfig ];
  
  # Example program configuration with secrets
  programs.git = {
    enable = true;
    extraConfig = {
      github.token = config.sops.secrets.github_token.path;
    };
  };
  
  # Example shell aliases using secrets
  programs.zsh.shellAliases = {
    # Use command substitution to read secret files
    "gh-auth" = "gh auth login --with-token < ${config.sops.secrets.github_token.path}";
  };
}

# Utility functions example
let
  sopsConfig = import ../sops-nix/sopsConfig.nix {
    inherit nixpkgs;
    user = "alex";
    environment = "production";
    hostname = "NIXY";
  };
  utils = sopsConfig.secretUtils;
in {
  # Check if secrets exist before using them
  conditionalService = lib.mkIf (utils.hasSecret "stripe_secret_key") {
    services.payment-processor = {
      enable = true;
      stripeKeyFile = utils.getSecretPath "stripe_secret_key";
    };
  };
  
  # Debug information
  secretsDebug = {
    environment = sopsConfig.environmentInfo.environment;
    secretCount = sopsConfig.environmentInfo.secretCount;
    availableSecrets = utils.listSecrets;
  };
}
