# 🔐 SOPS-nix Implementation Guide

A comprehensive guide for implementing and using SOPS-nix in production environments, covering setup, access control, and best practices.

## Table of Contents

- [Overview](#overview)
- [Production-Ready Implementation](#production-ready-implementation)
- [Setting Up Variables and Editing secrets.yaml](#setting-up-variables-and-editing-secretsyaml)
- [Access Control and Permissions](#access-control-and-permissions)
- [Determining Your Access](#determining-your-access)
- [User Access Matrix](#user-access-matrix)
- [Workflow Examples](#workflow-examples)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

SOPS-nix is the **de facto standard** for secrets management in Nix deployments. Our implementation follows production best practices with:

- **Age encryption** with environment-specific keys
- **Environment separation** (production, staging, development)
- **Host-specific access** control
- **Team collaboration** support
- **Automated deployment** integration

## Production-Ready Implementation

### Why SOPS-nix is Production Standard

1. **Native Nix Integration**: Seamless integration with NixOS/Darwin configurations
2. **Declarative Configuration**: Secrets defined alongside system configuration
3. **Git-Friendly**: Encrypted secrets can be safely committed to version control
4. **No External Dependencies**: No need for external secret management services in production
5. **Strong Community Support**: Widely adopted in the Nix ecosystem

### Our Implementation Architecture

```
.sops.yaml                    # Main SOPS configuration
sops-nix/
├── .sops.yaml               # SOPS-nix specific config
├── secrets.yaml             # Main secrets file
├── sopsConfig.nix           # Nix configuration
└── sync-age-key.sh          # Key synchronization

secrets/
├── production/secrets.yaml  # Production environment
├── staging/secrets.yaml     # Staging environment
├── development/secrets.yaml # Development environment
├── users/alex.yaml          # User-specific secrets
├── users/susu.yaml          # User-specific secrets
└── systems/
    ├── NIXY.yaml           # macOS system secrets
    ├── NIXSTATION64.yaml   # Linux workstation
    ├── NIXY2.yaml          # ARM Linux system
    └── NIXEDUP.yaml        # Mobile device
```

## Setting Up Variables and Editing secrets.yaml

### Step 1: Environment Setup

```bash
# Ensure you have the required tools
nix-shell -p sops age

# Verify your age key exists
ls ~/.config/sops/age/keys.txt

# If missing, generate one:
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# Get your public key for configuration
age-keygen -y ~/.config/sops/age/keys.txt
```

### Step 2: Understanding the .sops.yaml Configuration

Our `.sops.yaml` defines who can access which secrets:

```yaml
keys:
  # Admin users (full access)
  - &admin_alex age1qqveqstqurtaznmykpc3gntmrlrnyvlnahq4j2ldwlcjs2kqn9ysdj3rpq
  - &admin_susu age1qqveqstqurtaznmykpc3gntmrlrnyvlnahq4j2ldwlcjs2kqn9ysdj3rpq
  
  # Production team
  - &prod_team_1 age1234567890abcdef...
  - &prod_team_2 age1234567890abcdef...
  
  # System hosts
  - &host_nixy age1234567890abcdef...
  - &host_nixstation64 age1234567890abcdef...

creation_rules:
  # Production secrets - admin + production team + production hosts
  - path_regex: secrets/production/.*\.yaml$
    key_groups:
      - age:
        - *admin_alex
        - *admin_susu
        - *prod_team_1
        - *prod_team_2
        - *host_nixy
        - *host_nixstation64
  
  # Development secrets - admin + dev team + dev hosts
  - path_regex: secrets/development/.*\.yaml$
    key_groups:
      - age:
        - *admin_alex
        - *admin_susu
        - *host_nixy
```

### Step 3: Editing secrets.yaml Files

#### Basic Editing Workflow

```bash
# Navigate to your dotfiles directory
cd /Users/alex/.dotfiles

# Edit production secrets
nix-shell -p sops --run "sops secrets/production/secrets.yaml"

# Edit development secrets
nix-shell -p sops --run "sops secrets/development/secrets.yaml"

# Edit user-specific secrets
nix-shell -p sops --run "sops secrets/users/alex.yaml"

# Edit system-specific secrets
nix-shell -p sops --run "sops secrets/systems/NIXY.yaml"
```

#### Adding New Secrets

When the editor opens, add secrets in YAML format:

```yaml
# API Keys
api_keys:
  github_token: "ghp_xxxxxxxxxxxxxxxxxxxx"
  openai_api_key: "sk-xxxxxxxxxxxxxxxxxxxx"
  claude_api_key: "sk-ant-xxxxxxxxxxxxxxxxxxxx"

# Database Credentials
database:
  postgres_password: "secure_password_here"
  redis_password: "another_secure_password"

# Infrastructure
aws:
  access_key_id: "AKIAIOSFODNN7EXAMPLE"
  secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

# Nested secrets (creates directory structure)
services:
  monitoring:
    datadog_api_key: "xxxxxxxxxxxxxxxxxxxx"
    sentry_dsn: "https://xxxxxxxxxxxxxxxxxxxx"
```

#### Using Specific Editors

```bash
# Use vim
EDITOR=vim nix-shell -p sops --run "sops secrets/production/secrets.yaml"

# Use VS Code
EDITOR="code --wait" nix-shell -p sops --run "sops secrets/production/secrets.yaml"

# Use nano
EDITOR=nano nix-shell -p sops --run "sops secrets/production/secrets.yaml"
```

## Access Control and Permissions

### How Access Control Works

Access is determined by **cryptographic keys**, not file permissions:

1. **Encryption**: Each secret file is encrypted with specific age/PGP keys
2. **Decryption**: Only holders of the corresponding private keys can decrypt
3. **Key Groups**: Multiple keys can be specified for redundancy and team access

### Key Types in Our Setup

#### Admin Keys
- **alex**: Full access to all environments and systems
- **susu**: Full access to all environments and systems

#### Environment-Specific Keys
- **Production Team**: Access to production secrets only
- **Staging Team**: Access to staging secrets only
- **Development Team**: Access to development secrets only

#### System-Specific Keys
- **NIXY**: macOS system secrets
- **NIXSTATION64**: Linux workstation secrets
- **NIXY2**: ARM Linux system secrets
- **NIXEDUP**: Mobile device secrets

#### User-Specific Keys
- **alex**: Personal secrets (API keys, personal configs)
- **susu**: Personal secrets (API keys, personal configs)

## Determining Your Access

### Check Which Files You Can Access

```bash
# List all secret files
find secrets -name "*.yaml" -type f

# Test if you can decrypt a specific file
nix-shell -p sops --run "sops -d secrets/production/secrets.yaml" > /dev/null 2>&1 && echo "✅ Access granted" || echo "❌ Access denied"

# Check multiple files
for file in secrets/*/*.yaml; do
  echo -n "Testing $file: "
  nix-shell -p sops --run "sops -d $file" > /dev/null 2>&1 && echo "✅" || echo "❌"
done
```

### View File Metadata

```bash
# See who has access to a specific file
nix-shell -p sops --run "sops -s secrets/production/secrets.yaml"

# This shows all age recipients who can decrypt the file
```

### Verify Your Key

```bash
# Check your age key
cat ~/.config/sops/age/keys.txt

# Get your public key
age-keygen -y ~/.config/sops/age/keys.txt

# Verify it matches the configuration
grep -r "$(age-keygen -y ~/.config/sops/age/keys.txt)" .sops.yaml
```

## User Access Matrix

Based on our current `.sops.yaml` configuration:

| User/System | Production | Staging | Development | User Secrets | System Secrets |
|-------------|------------|---------|-------------|--------------|-----------------|
| alex (admin) | ✅ | ✅ | ✅ | ✅ alex.yaml | ✅ All systems |
| susu (admin) | ✅ | ✅ | ✅ | ✅ susu.yaml | ✅ All systems |
| NIXY | ✅ | ✅ | ✅ | ❌ | ✅ NIXY.yaml |
| NIXSTATION64 | ✅ | ✅ | ✅ | ❌ | ✅ NIXSTATION64.yaml |
| NIXY2 | ✅ | ✅ | ✅ | ❌ | ✅ NIXY2.yaml |
| NIXEDUP | ✅ | ✅ | ✅ | ❌ | ✅ NIXEDUP.yaml |

### Adding New Users

To add a new user with specific access:

1. **Generate their age key**:
   ```bash
   # User generates their own key
   age-keygen -o ~/.config/sops/age/keys.txt
   age-keygen -y ~/.config/sops/age/keys.txt  # Share public key
   ```

2. **Add to .sops.yaml**:
   ```yaml
   keys:
     - &new_user_dev age1newuserkey...
   
   creation_rules:
     - path_regex: secrets/development/.*\.yaml$
       key_groups:
         - age:
           - *admin_alex
           - *admin_susu
           - *new_user_dev  # Add here
   ```

3. **Re-encrypt affected files**:
   ```bash
   nix-shell -p sops --run "sops updatekeys secrets/development/secrets.yaml"
   ```

## Workflow Examples

### Daily Development Workflow

```bash
# 1. Edit development secrets
nix-shell -p sops --run "sops secrets/development/secrets.yaml"

# 2. Add a new API key
# In the editor, add:
# api_keys:
#   new_service: "your-api-key-here"

# 3. Use in Nix configuration
# In your .nix file:
# sops.secrets.new-service-key = {
#   sopsFile = ../secrets/development/secrets.yaml;
#   key = "api_keys.new_service";
# };

# 4. Deploy the change
darwin-rebuild switch --flake .#NIXY
```

### Production Deployment Workflow

```bash
# 1. Edit production secrets (admin only)
nix-shell -p sops --run "sops secrets/production/secrets.yaml"

# 2. Test decryption
nix-shell -p sops --run "sops -d secrets/production/secrets.yaml" > /dev/null

# 3. Deploy to production system
# This happens automatically via CI/CD or manual deployment
```

### Adding a New System

```bash
# 1. Generate system's age key from SSH host key
ssh-keyscan -t ed25519 new-system.example.com | ssh-to-age

# 2. Add to .sops.yaml
# keys:
#   - &host_newsystem age1newsystemkey...

# 3. Create system-specific secrets
nix-shell -p sops --run "sops secrets/systems/newsystem.yaml"

# 4. Update existing secrets if needed
nix-shell -p sops --run "sops updatekeys secrets/production/secrets.yaml"
```

## Troubleshooting

### Common Issues and Solutions

#### "No such file or directory" Error

```bash
# Ensure the file is tracked in Git
git add secrets/production/secrets.yaml

# Verify the file exists
ls -la secrets/production/secrets.yaml
```

#### "Failed to decrypt" Error

```bash
# Check your age key
test -f ~/.config/sops/age/keys.txt && echo "Key exists" || echo "Key missing"

# Verify key permissions
ls -la ~/.config/sops/age/keys.txt
# Should show: -rw------- (600)

# Fix permissions if needed
chmod 600 ~/.config/sops/age/keys.txt
```

#### "No matching creation rule" Error

```bash
# Check .sops.yaml syntax
cat .sops.yaml

# Verify the file path matches the regex
echo "secrets/production/secrets.yaml" | grep -E "secrets/production/.*\.yaml$"
```

#### Wrong Editor Opens

```bash
# Set your preferred editor
export EDITOR=vim
nix-shell -p sops --run "sops secrets/production/secrets.yaml"

# Or specify inline
EDITOR=code nix-shell -p sops --run "sops secrets/production/secrets.yaml"
```

### Recovery Procedures

#### Lost Age Key

If you lose your age key but have admin access:

```bash
# 1. Generate new key
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# 2. Get new public key
age-keygen -y ~/.config/sops/age/keys.txt

# 3. Update .sops.yaml with new public key
# 4. Re-encrypt all files you need access to
nix-shell -p sops --run "sops updatekeys secrets/development/secrets.yaml"
```

## Best Practices

### Security Best Practices

1. **Key Management**:
   - Store age keys securely (`~/.config/sops/age/keys.txt`)
   - Set proper permissions (600)
   - Backup keys securely (encrypted external storage)

2. **Environment Separation**:
   - Never use production secrets in development
   - Use different keys for different environments
   - Implement proper access controls

3. **Regular Auditing**:
   ```bash
   # Check who has access to what
   ./scripts/secrets-manager.sh audit
   
   # Validate all secrets can be decrypted
   ./scripts/secrets-manager.sh validate
   ```

### Operational Best Practices

1. **Key Rotation**:
   ```bash
   # Rotate keys regularly (monthly/quarterly)
   ./scripts/secrets-manager.sh rotate-keys
   ```

2. **Team Onboarding**:
   - Generate age key for new team member
   - Add to appropriate creation rules
   - Re-encrypt relevant secrets
   - Document access levels

3. **Monitoring**:
   - Monitor secret access patterns
   - Alert on unauthorized access attempts
   - Regular security audits

### Development Best Practices

1. **Local Development**:
   - Use development environment secrets
   - Never commit plaintext secrets
   - Use `.env` files for local overrides (gitignored)

2. **CI/CD Integration**:
   - Secrets are automatically available in `/run/secrets/`
   - No manual secret injection needed
   - Atomic deployments with secret updates

3. **Testing**:
   - Use test-specific secrets for CI
   - Mock external services in tests
   - Validate secret availability in deployment tests

---

This implementation guide provides comprehensive coverage of SOPS-nix usage in our production environment. For additional help, consult the [main secrets guide](secrets-guide.md) or run `./scripts/secrets-manager.sh --help`.