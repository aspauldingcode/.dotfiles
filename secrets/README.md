# Secrets Management with sops-nix

This directory contains the production-ready secrets management setup using `sops-nix` for multi-user and multi-device deployments.

## 📁 Directory Structure

```
secrets/
├── README.md                    # This documentation
├── development/
│   └── secrets.yaml            # Development environment secrets
├── production/
│   └── secrets.yaml            # Production environment secrets
├── staging/
│   └── secrets.yaml            # Staging environment secrets
├── systems/
│   ├── NIXY.yaml               # System-specific secrets for NIXY (Apple Silicon)
│   ├── NIXI.yaml               # System-specific secrets for NIXI (Intel)
│   ├── NIXY2.yaml              # System-specific secrets for NIXY2 (if needed)
│   └── NIXSTATION64.yaml       # System-specific secrets for NIXSTATION64 (if needed)
└── users/
    └── alex.yaml               # User-specific secrets for alex

sops-nix/
├── sopsConfig.nix              # Main configuration module
├── secrets.yaml                # Legacy secrets (backward compatibility)
└── .sops.yaml                  # SOPS encryption rules
```

## 🔐 Security Features

### Environment Separation

- **Production**: Full production secrets with strict access controls
- **Staging**: Uses production secrets for consistency
- **Development**: Subset of production + development-specific secrets
- **Legacy**: Backward compatibility for existing setups

### Access Control

- **Key Groups**: Organized by role (admin, team members, systems)
- **Granular Permissions**: Different access levels per environment
- **Multi-Key Support**: Age and PGP keys for redundancy

### Security Hardening

- ✅ Validation of secret files on activation
- ✅ Proper file permissions (0400 for secrets, 0444 for certificates)
- ✅ Multiple SSH key fallbacks
- ✅ Environment validation
- ✅ Path existence checks
- ✅ Error handling and validation

## 🚀 Usage

### Basic Usage in NixOS Configuration

```nix
{ config, pkgs, ... }:
let
  sopsConfig = import ../sops-nix/sopsConfig.nix {
    inherit nixpkgs;
    user = "alex";
    environment = "production"; # or "staging", "development"
    hostname = config.networking.hostName;
  };
in {
  imports = [ sopsConfig.nixosSopsConfig ];
  
  # Access secrets in your configuration
  services.myapp.apiKey = config.sops.secrets.anthropic_api_key.path;
}
```

### Basic Usage in Home Manager

```nix
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
  
  # Access secrets in your home configuration
  programs.git.extraConfig.github.token = config.sops.secrets.github_token.path;
}
```

### Utility Functions

```nix
let
  sopsConfig = import ../sops-nix/sopsConfig.nix { /* ... */ };
  utils = sopsConfig.secretUtils;
in {
  # Check if a secret exists
  hasApiKey = utils.hasSecret "anthropic_api_key";
  
  # Get secret path
  apiKeyPath = utils.getSecretPath "anthropic_api_key";
  
  # List all available secrets
  allSecrets = utils.listSecrets;
  
  # Validate environment
  isValidEnv = utils.validateEnvironment "production";
}
```

## 🔑 Secret Categories

### API Keys and External Services

- `anthropic_api_key` - Anthropic Claude API key
- `openai_api_key` - OpenAI API key
- `azure_openai_api_key` - Azure OpenAI API key
- `github_token` - GitHub personal access token
- `gitlab_token` - GitLab access token

### Cloud Infrastructure

- `aws_access_key_id` - AWS access key
- `aws_secret_access_key` - AWS secret key
- `aws_session_token` - AWS session token
- `gcp_service_account_key` - Google Cloud service account
- `azure_client_secret` - Azure client secret
- `cloudflare_api_token` - Cloudflare API token
- `digitalocean_token` - DigitalOcean API token

### Database and Storage

- `database_url` - Primary database connection string
- `database_password` - Database password
- `redis_url` - Redis connection string
- `redis_password` - Redis password
- `s3_bucket_key` - S3 bucket access key

### Monitoring and Observability

- `datadog_api_key` - Datadog API key
- `newrelic_license_key` - New Relic license key
- `sentry_dsn` - Sentry DSN
- `prometheus_token` - Prometheus access token
- `grafana_api_key` - Grafana API key

### Security and Certificates

- `backup_encryption_key` - Backup encryption key
- `disaster_recovery_key` - Disaster recovery key
- `tls_private_key` - TLS private key (root owned)
- `tls_certificate` - TLS certificate (world readable)
- `ssh_deploy_key` - SSH deployment key
- `gpg_private_key` - GPG private key

### Application Secrets

- `jwt_secret` - JWT signing secret
- `session_secret` - Session encryption secret
- `encryption_key` - Application encryption key
- `webhook_secret` - Webhook validation secret

### Third-party Integrations

- `stripe_secret_key` - Stripe secret key
- `paypal_client_secret` - PayPal client secret
- `twilio_auth_token` - Twilio authentication token
- `sendgrid_api_key` - SendGrid API key
- `slack_webhook_url` - Slack webhook URL

### Development-specific Secrets

- `test_user_password` - Test user password
- `test_api_key` - Test API key
- `local_ssl_cert` - Local SSL certificate
- `local_ssl_key` - Local SSL key
- `dev_database_url` - Development database URL
- `wifi_dev_network_password` - Development WiFi password
- `vpn_dev_config` - Development VPN configuration
- `docker_registry_token` - Docker registry token
- `npm_auth_token` - NPM authentication token
- `pypi_token` - PyPI token

## 🛠️ Management Commands

### Encrypting New Secrets

```bash
# For production environment
sops secrets/production/secrets.yaml

# For development environment
sops secrets/development/secrets.yaml

# For user-specific secrets
sops secrets/users/alex.yaml

# For system-specific secrets
sops secrets/systems/NIXY.yaml
sops secrets/systems/NIXI.yaml
```

### Key Management

```bash
# Generate new age key
age-keygen -o ~/.config/sops/age/keys.txt

# Import age key to sops
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

# Rotate keys (update .sops.yaml with new keys, then re-encrypt)
sops updatekeys secrets/production/secrets.yaml
```

### Validation

```bash
# Validate secret files
sops --decrypt secrets/production/secrets.yaml > /dev/null

# Check configuration
nix eval --json .#nixosConfigurations.NIXY.config.sops.secrets --apply builtins.attrNames
```

## 🔄 Migration Guide

### From Legacy Setup

1. **Backup existing secrets**:

   ```bash
   cp sops-nix/secrets.yaml sops-nix/secrets.yaml.backup
   ```

1. **Migrate secrets to new structure**:

   ```bash
   # Copy relevant secrets to appropriate environment files
   sops secrets/development/secrets.yaml
   # Add your secrets here
   ```

1. **Update configurations**:

   ```nix
   # Change from:
   sops.defaultSopsFile = ../sops-nix/secrets.yaml;

   # To:
   imports = [ (import ../sops-nix/sopsConfig.nix {
     inherit nixpkgs;
     user = "alex";
     environment = "development";
     hostname = config.networking.hostName;
   }).nixosSopsConfig ];
   ```

### Adding New Environments

1. **Create environment directory**:

   ```bash
   mkdir -p secrets/testing
   ```

1. **Add to sopsConfig.nix**:

   ```nix
   validEnvironments = ["production" "staging" "development" "testing" "legacy"];
   secretFiles = {
     # ... existing ...
     testing = ../secrets/testing/secrets.yaml;
   };
   ```

1. **Update .sops.yaml**:

   ```yaml
   creation_rules:
     - path_regex: secrets/testing/.*\.yaml$
       key_groups:
         - age:
             - *admin_alex
             - *testing_key
   ```

## 🚨 Best Practices

### Security

- ✅ Never commit unencrypted secrets
- ✅ Use different keys for different environments
- ✅ Regularly rotate keys and secrets
- ✅ Use minimal permissions (0400 for secrets)
- ✅ Validate secret files before deployment
- ✅ Use system-specific secrets for sensitive data

### Organization

- ✅ Group secrets by category and environment
- ✅ Use descriptive secret names
- ✅ Document secret purposes and usage
- ✅ Keep development and production secrets separate
- ✅ Use consistent naming conventions

### Deployment

- ✅ Test secret access in staging before production
- ✅ Use environment-specific configurations
- ✅ Implement proper error handling
- ✅ Monitor secret access and usage
- ✅ Have disaster recovery procedures

## 🐛 Troubleshooting

### Common Issues

1. **Secret not found**:

   ```
   Error: Secret 'my_secret' not found in environment 'production'
   ```

   - Check if secret exists in the environment's secrets file
   - Verify secret name spelling
   - Ensure environment is correctly set

1. **Permission denied**:

   ```
   Error: Permission denied accessing /run/secrets/my_secret
   ```

   - Check file ownership and permissions
   - Verify user has access to the secret
   - Check if secret is properly decrypted

1. **Invalid environment**:

   ```
   Error: Invalid environment 'prod'. Must be one of: production, staging, development, legacy
   ```

   - Use exact environment names from validEnvironments
   - Check spelling and case sensitivity

1. **Key not found**:

   ```
   Error: no key found for decryption
   ```

   - Verify age key is properly configured
   - Check SSH host keys exist
   - Ensure .sops.yaml has correct key references

### Debug Information

```nix
# Get environment information
let
  sopsConfig = import ../sops-nix/sopsConfig.nix { /* ... */ };
in {
  inherit (sopsConfig) environmentInfo;
  # Shows: environment, hostname, user, validation status, secret counts
}
```

## 📚 References

- [sops-nix Documentation](https://github.com/Mic92/sops-nix)
- [SOPS Documentation](https://github.com/mozilla/sops)
- [Age Encryption](https://github.com/FiloSottile/age)
- [NixOS Manual - SOPS](https://nixos.org/manual/nixos/stable/index.html#module-services-sops)

## 🤝 Contributing

When adding new secrets:

1. Add to appropriate environment in `sopsConfig.nix`
1. Update this documentation
1. Add encryption rules to `.sops.yaml`
1. Test in development environment first
1. Document the secret's purpose and usage
