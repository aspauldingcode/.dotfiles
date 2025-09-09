{
  nixpkgs,
  user,
  environment ? "development", # production, staging, development
  hostname ? "unknown",
}: let
  # Environment-specific secret files
  secretFiles = {
    development = ../secrets/development/secrets.yaml;
    personal = ../secrets/users/alex.yaml;
  };

  # Base sops configuration
  commonSopsConfigBase = { environment ? "development" }: {
    sops = {
      defaultSopsFile = secretFiles.${environment} or secretFiles.development;
      defaultSopsFormat = "yaml";

      age = {
        sshKeyPaths = [
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_rsa_key"
        ];
        keyFile = "/var/lib/sops-nix/key.txt";
        generateKey = true;
      };

      validateSopsFiles = true;
      keepGenerations = 5;
    };
  };

  # Simplified secret configuration with standard permissions
  defaultSecretConfig = {
    owner = user;
    mode = "0400";
  };

  # Core secrets used across environments
  coreSecrets = {
    # API Keys
    openai_api_key = defaultSecretConfig;
    claude_api_key = defaultSecretConfig;
    azure_openai_api_key = defaultSecretConfig;
    github_token = defaultSecretConfig;
    bedrock_key = defaultSecretConfig;

    # WiFi passwords
    wifi_home_password = defaultSecretConfig;
  };

  # Select secrets based on environment
  environmentSecrets = {
    development = coreSecrets;
    personal = coreSecrets;
  };

  # Unified system sops configuration for both NixOS and Darwin
  systemSopsConfig = { environment ? "development", ... }: { config, pkgs, ... }: nixpkgs.lib.recursiveUpdate (commonSopsConfigBase { inherit environment; }) {
    sops = {
      secrets = environmentSecrets.${environment} or environmentSecrets.development;

      # Validation and error handling
      validateSopsFiles = true;

      # Environment-specific settings
      environment = {
        SOPS_ENVIRONMENT = nixpkgs.lib.mkForce environment;
        SOPS_HOSTNAME = hostname;
        SOPS_USER = user;
      };

      # Template configuration for environment files
      templates = {
        # Environment variables template for applications
        "secrets.env" = {
          content = ''
            # Application Environment Variables
            export OPENAI_API_KEY="${config.sops.placeholder."openai_api_key"}"
            export CLAUDE_API_KEY="${config.sops.placeholder."claude_api_key"}"
            export AZURE_OPENAI_API_KEY="${config.sops.placeholder."azure_openai_api_key"}"
            export GH_TOKEN="${config.sops.placeholder."github_token"}"
            export BEDROCK_KEYS="${config.sops.placeholder."bedrock_key"}"
          '';
          owner = user;
          group = "staff";
          mode = "0644";
        };
      };
    };

    # System-wide environment variables for Darwin
    environment.variables = {
      OPENAI_API_KEY = config.sops.placeholder."openai_api_key";
      CLAUDE_API_KEY = config.sops.placeholder."claude_api_key";
      AZURE_OPENAI_API_KEY = config.sops.placeholder."azure_openai_api_key";
      GH_TOKEN = config.sops.placeholder."github_token";
      BEDROCK_KEYS = config.sops.placeholder."bedrock_key";
    };

    # Activation script to source secrets in shell profiles
    system.activationScripts.sopsSecrets.text = ''
      # Source secrets.env in system shell profiles
      if [ -f /run/secrets/rendered/secrets.env ]; then
        # Add sourcing to /etc/zshrc if it exists
        if [ -f /etc/zshrc ]; then
          if ! grep -q "secrets.env" /etc/zshrc; then
            echo "# Source development secrets" >> /etc/zshrc
            echo "[ -f /run/secrets/rendered/secrets.env ] && source /run/secrets/rendered/secrets.env" >> /etc/zshrc
          fi
        fi

        # Add sourcing to /etc/bashrc if it exists
        if [ -f /etc/bashrc ]; then
          if ! grep -q "secrets.env" /etc/bashrc; then
            echo "# Source development secrets" >> /etc/bashrc
            echo "[ -f /run/secrets/rendered/secrets.env ] && source /run/secrets/rendered/secrets.env" >> /etc/bashrc
          fi
        fi
      fi
    '';
  };
};

  # Home Manager secrets (without owner and mode, with proper attribute handling)
  hmSecrets = { environment ? "development" }: builtins.mapAttrs (
    name: value:
      removeAttrs value [
        "owner"
        "mode"
      ]
  ) (environmentSecrets.${environment} or environmentSecrets.development);

  # Home Manager-specific sops configuration
  hmSopsConfig = { environment ? "development", ... }: { config, pkgs, ... }: nixpkgs.lib.recursiveUpdate (commonSopsConfigBase { inherit environment; }) {
    sops = {
      secrets = hmSecrets { inherit environment; };

      # Home Manager specific settings
      age.keyFile = "/home/${user}/.config/sops/age/keys.txt";
      defaultSymlinkPath = "/run/user/1000/secrets";
      defaultSecretsMountPoint = "/run/user/1000/secrets.d";
    };
  };

  # Simple utility for getting secret paths
  getSecretPath = secretName: "/run/secrets/${secretName}";

in {
  inherit
    systemSopsConfig
    hmSopsConfig
    getSecretPath
    ;
}
