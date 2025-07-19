# 🔐 Secrets Management Guide

This guide covers comprehensive secrets management using SOPS (Secrets OPerationS) with age encryption in our Nix flake configuration.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Setup](#setup)
- [Environment Structure](#environment-structure)
- [Common Operations](#common-operations)
- [Integration with Nix](#integration-with-nix)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## Overview

Our secrets management system provides:

- **Encrypted Storage**: All secrets are encrypted at rest using age/PGP
- **Environment Separation**: Different secrets for production, staging, development
- **Granular Access**: User and system-specific secret management
- **Version Control Safe**: Encrypted secrets can be safely committed to Git
- **Automated Management**: Scripts for common operations and key rotation

## Architecture

### Directory Structure

```
secrets/
├── production/          # Production environment secrets
│   └── secrets.yaml    # Main production secrets file
├── staging/            # Staging environment secrets
│   └── secrets.yaml    # Staging-specific secrets
├── development/        # Development environment secrets
│   └── secrets.yaml    # Local development secrets
├── users/              # User-specific secrets
│   ├── alex.yaml      # User alex's personal secrets
│   └── susu.yaml      # User susu's personal secrets
└── systems/            # System-specific secrets
    ├── NIXY.yaml      # macOS system secrets
    ├── NIXSTATION64.yaml  # Linux workstation secrets
    ├── NIXY2.yaml     # ARM Linux secrets
    └── NIXEDUP.yaml   # Mobile device secrets
```

### Encryption Keys

- **Age Keys**: Primary encryption method using age public/private key pairs
- **PGP Keys**: Optional additional encryption layer for team environments
- **SSH Host Keys**: System-level encryption using SSH host keys

## Setup

### Initial Setup

1. **Install Required Tools**:
   ```bash
   # Install age
   nix-env -iA nixpkgs.age
   
   # Install SOPS
   nix-env -iA nixpkgs.sops
   ```

2. **Generate Age Key**:
   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   
   # Display public key for configuration
   age-keygen -y ~/.config/sops/age/keys.txt
   ```

3. **Initialize Secrets Management**:
   ```bash
   ./scripts/secrets-manager.sh init
   ```

### Configuration Files

#### `.sops.yaml` (Main Configuration)

```yaml
creation_rules:
  # Production secrets
  - path_regex: secrets/production/.*\.yaml$
    age: age1234567890abcdef...
    pgp: 1234567890ABCDEF...
    
  # Development secrets  
  - path_regex: secrets/development/.*\.yaml$
    age: age1234567890abcdef...
    
  # User-specific secrets
  - path_regex: secrets/users/.*\.yaml$
    age: age1234567890abcdef...
    
  # System-specific secrets
  - path_regex: secrets/systems/.*\.yaml$
    age: age1234567890abcdef...
```

## Environment Structure

### Production Secrets (`secrets/production/secrets.yaml`)

```yaml
# API Keys and External Services
api_keys:
  github_token: ENC[AES256_GCM,data:...,tag:...]
  claude_api_key: ENC[AES256_GCM,data:...,tag:...]
  openai_api_key: ENC[AES256_GCM,data:...,tag:...]

# Database Credentials
database:
  postgres_password: ENC[AES256_GCM,data:...,tag:...]
  redis_password: ENC[AES256_GCM,data:...,tag:...]

# Infrastructure Secrets
infrastructure:
  aws_access_key: ENC[AES256_GCM,data:...,tag:...]
  aws_secret_key: ENC[AES256_GCM,data:...,tag:...]
  
# Monitoring and Logging
monitoring:
  datadog_api_key: ENC[AES256_GCM,data:...,tag:...]
  sentry_dsn: ENC[AES256_GCM,data:...,tag:...]
```

### Development Secrets (`secrets/development/secrets.yaml`)

```yaml
# Development API Keys (often with limited scope)
api_keys:
  github_token: ENC[AES256_GCM,data:...,tag:...]
  claude_api_key: ENC[AES256_GCM,data:...,tag:...]

# Local Development
local:
  wifi_password: ENC[AES256_GCM,data:...,tag:...]
  test_database_url: ENC[AES256_GCM,data:...,tag:...]
```

### User Secrets (`secrets/users/alex.yaml`)

```yaml
# Personal API Keys
personal:
  spotify_client_id: ENC[AES256_GCM,data:...,tag:...]
  spotify_client_secret: ENC[AES256_GCM,data:...,tag:...]
  
# Cloud Storage
cloud:
  dropbox_token: ENC[AES256_GCM,data:...,tag:...]
  google_drive_credentials: ENC[AES256_GCM,data:...,tag:...]

# Personal WiFi and Networks
networks:
  home_wifi_password: ENC[AES256_GCM,data:...,tag:...]
  work_wifi_password: ENC[AES256_GCM,data:...,tag:...]
```

### System Secrets (`secrets/systems/NIXY.yaml`)

```yaml
# System Administration
admin:
  admin_password: ENC[AES256_GCM,data:...,tag:...]
  filevault_recovery_key: ENC[AES256_GCM,data:...,tag:...]

# System Certificates
certificates:
  ssl_private_key: ENC[AES256_GCM,data:...,tag:...]
  ca_certificate: ENC[AES256_GCM,data:...,tag:...]

# System Monitoring
monitoring:
  system_token: ENC[AES256_GCM,data:...,tag:...]
  log_aggregation_key: ENC[AES256_GCM,data:...,tag:...]
```

## Common Operations

### Creating Secrets

#### Create Environment-Specific Secrets
```bash
# Create production secrets
./scripts/secrets-manager.sh create production api-keys

# Create development secrets
./scripts/secrets-manager.sh create development local-config

# Create staging secrets
./scripts/secrets-manager.sh create staging test-data
```

#### Create User-Specific Secrets
```bash
# Create secrets for user alex
./scripts/secrets-manager.sh create-user alex

# Create secrets for user susu
./scripts/secrets-manager.sh create-user susu
```

#### Create System-Specific Secrets
```bash
# Create secrets for NIXY system
./scripts/secrets-manager.sh create-system NIXY

# Create secrets for NIXSTATION64
./scripts/secrets-manager.sh create-system NIXSTATION64
```

### Editing Secrets

```bash
# Edit production secrets
./scripts/secrets-manager.sh edit production secrets.yaml

# Edit user secrets
./scripts/secrets-manager.sh edit users alex.yaml

# Edit system secrets
./scripts/secrets-manager.sh edit systems NIXY.yaml

# Edit with specific editor
EDITOR=vim ./scripts/secrets-manager.sh edit production secrets.yaml
```

### Viewing Secrets

```bash
# View decrypted secrets (be careful!)
./scripts/secrets-manager.sh decrypt production secrets.yaml

# View specific key
./scripts/secrets-manager.sh get production secrets.yaml api_keys.github_token

# List all secret files
./scripts/secrets-manager.sh list
```

### Key Management

#### Rotate Age Keys
```bash
# Backup current keys
./scripts/secrets-manager.sh backup

# Generate new age key
./scripts/secrets-manager.sh rotate-keys

# Re-encrypt all secrets with new key
./scripts/secrets-manager.sh re-encrypt-all
```

#### Add New Recipients
```bash
# Add new age public key to .sops.yaml
./scripts/secrets-manager.sh add-recipient age1234567890abcdef...

# Add PGP key
./scripts/secrets-manager.sh add-recipient --pgp 1234567890ABCDEF
```

### Validation and Auditing

```bash
# Validate all secrets can be decrypted
./scripts/secrets-manager.sh validate

# Audit secret usage
./scripts/secrets-manager.sh audit

# Check for secrets in Git history
./scripts/secrets-manager.sh scan-history

# Generate security report
./scripts/secrets-manager.sh security-report
```

## Integration with Nix

### Basic Secret Usage

```nix
{ config, ... }:
{
  # Import SOPS configuration
  imports = [ ./sops-nix/sopsConfig.nix ];
  
  # Define secrets
  sops.secrets.github-token = {
    sopsFile = ../secrets/production/secrets.yaml;
    owner = "alex";
    mode = "0400";
    path = "/run/secrets/github-token";
  };
  
  # Use in services
  services.myservice = {
    enable = true;
    tokenFile = config.sops.secrets.github-token.path;
  };
}
```

### Environment-Specific Secrets

```nix
{ config, lib, ... }:
let
  environment = lib.mkDefault "development";
  secretsFile = ../secrets/${environment}/secrets.yaml;
in
{
  sops.defaultSopsFile = secretsFile;
  
  sops.secrets = {
    api-key = {
      owner = config.users.users.alex.name;
      mode = "0400";
    };
    
    database-password = {
      owner = "postgres";
      group = "postgres";
      mode = "0440";
    };
  };
}
```

### User-Specific Secrets in Home Manager

```nix
{ config, ... }:
{
  imports = [ ../sops-nix/sopsConfig.nix ];
  
  sops.secrets.personal-api-key = {
    sopsFile = ../secrets/users/alex.yaml;
    path = "${config.home.homeDirectory}/.config/api-key";
  };
  
  programs.git = {
    extraConfig = {
      github.token = "$(cat ${config.sops.secrets.personal-api-key.path})";
    };
  };
}
```

### System-Specific Secrets

```nix
{ config, ... }:
let
  hostname = config.networking.hostName;
  systemSecretsFile = ../secrets/systems/${hostname}.yaml;
in
{
  sops.secrets.admin-password = {
    sopsFile = systemSecretsFile;
    neededForUsers = true;
  };
  
  users.users.admin = {
    hashedPasswordFile = config.sops.secrets.admin-password.path;
  };
}
```

## Security Best Practices

### Key Management

1. **Regular Key Rotation**:
   ```bash
   # Rotate keys monthly
   ./scripts/secrets-manager.sh rotate-keys
   ```

2. **Secure Key Storage**:
   - Store age keys in `~/.config/sops/age/keys.txt`
   - Set proper file permissions: `chmod 600 ~/.config/sops/age/keys.txt`
   - Backup keys securely (encrypted external storage)

3. **Multiple Recipients**:
   - Use multiple age keys for redundancy
   - Include team members' keys for shared secrets
   - Use PGP keys for additional security layer

### Secret Organization

1. **Environment Separation**:
   - Never use production secrets in development
   - Use different keys for different environments
   - Implement proper access controls

2. **Principle of Least Privilege**:
   - Give users access only to secrets they need
   - Use system-specific secrets for system-level access
   - Separate user secrets from system secrets

3. **Regular Auditing**:
   ```bash
   # Weekly security audit
   ./scripts/secrets-manager.sh audit
   
   # Check for exposed secrets
   ./scripts/secrets-manager.sh scan-history
   ```

### Git Security

1. **Pre-commit Hooks**:
   ```bash
   # Install pre-commit hook
   ./scripts/secrets-manager.sh install-hooks
   ```

2. **Regular Scanning**:
   ```bash
   # Scan for accidentally committed secrets
   git log --all --full-history --grep='password\|secret\|key\|token'
   ```

## Troubleshooting

### Common Issues

#### Cannot Decrypt Secrets

```bash
# Check age key exists
test -f ~/.config/sops/age/keys.txt && echo "Age key found" || echo "Age key missing"

# Verify key format
age-keygen -y ~/.config/sops/age/keys.txt

# Check SOPS configuration
sops --version
cat .sops.yaml
```

#### Wrong File Permissions

```bash
# Fix age key permissions
chmod 600 ~/.config/sops/age/keys.txt

# Fix secrets directory permissions
find secrets -type f -exec chmod 644 {} \;
```

#### SOPS Configuration Issues

```bash
# Validate SOPS configuration
./scripts/secrets-manager.sh validate

# Check specific file
sops --decrypt secrets/production/secrets.yaml
```

### Recovery Procedures

#### Lost Age Key

1. **If you have backup**:
   ```bash
   # Restore from backup
   cp /path/to/backup/keys.txt ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
   ```

2. **If no backup available**:
   ```bash
   # Generate new key
   age-keygen -o ~/.config/sops/age/keys.txt
   
   # Update .sops.yaml with new public key
   age-keygen -y ~/.config/sops/age/keys.txt
   
   # Re-encrypt all secrets (requires access to plaintext)
   ./scripts/secrets-manager.sh re-encrypt-all
   ```

#### Corrupted Secrets File

```bash
# Check file integrity
sops --decrypt secrets/production/secrets.yaml > /dev/null

# Restore from Git history
git log --oneline secrets/production/secrets.yaml
git checkout <commit-hash> -- secrets/production/secrets.yaml
```

## Advanced Usage

### Custom Encryption Rules

```yaml
# .sops.yaml
creation_rules:
  # High-security production secrets
  - path_regex: secrets/production/critical/.*\.yaml$
    age: age1234567890abcdef...
    pgp: 1234567890ABCDEF...
    encrypted_regex: '^(password|key|token|secret)$'
    
  # Development secrets with relaxed rules
  - path_regex: secrets/development/.*\.yaml$
    age: age1234567890abcdef...
    encrypted_regex: '^(password|key)$'
```

### Templating with Secrets

```nix
{ config, ... }:
{
  # Template configuration with secrets
  environment.etc."myapp/config.json".text = builtins.toJSON {
    api_key = "$(cat ${config.sops.secrets.api-key.path})";
    database_url = "postgresql://user:$(cat ${config.sops.secrets.db-password.path})@localhost/mydb";
  };
}
```

### Integration with External Tools

```bash
# Export secrets for external tools
./scripts/secrets-manager.sh export production secrets.yaml > .env

# Import secrets from external source
./scripts/secrets-manager.sh import production secrets.yaml < external-secrets.json
```

### Automated Secret Rotation

```bash
# Set up automated rotation (cron job)
0 0 1 * * /path/to/.dotfiles/scripts/secrets-manager.sh rotate-keys --auto
```

## Monitoring and Alerting

### Secret Usage Monitoring

```bash
# Monitor secret access
./scripts/secrets-manager.sh monitor

# Generate usage report
./scripts/secrets-manager.sh usage-report
```

### Security Alerts

```bash
# Set up alerts for secret changes
./scripts/secrets-manager.sh setup-alerts

# Check for security issues
./scripts/secrets-manager.sh security-check
```

---

This guide provides comprehensive coverage of secrets management in our Nix flake configuration. For additional help, consult the troubleshooting section or run `./scripts/secrets-manager.sh --help` for command-specific guidance.