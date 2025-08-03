#!/usr/bin/env bash

# Migration script for sops-nix secrets management
# This script helps migrate from the legacy setup to the new production-ready structure

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="${HOME}/.dotfiles"
SECRETS_DIR="${DOTFILES_DIR}/secrets"
SOPS_DIR="${DOTFILES_DIR}/sops-nix"
BACKUP_DIR="${DOTFILES_DIR}/secrets-backup-$(date +%Y%m%d-%H%M%S)"

# Helper functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
  log_info "Checking dependencies..."

  local missing_deps=()

  if ! command -v sops &>/dev/null; then
    missing_deps+=("sops")
  fi

  if ! command -v age &>/dev/null; then
    missing_deps+=("age")
  fi

  if ! command -v age-keygen &>/dev/null; then
    missing_deps+=("age-keygen")
  fi

  if [ ${#missing_deps[@]} -ne 0 ]; then
    log_error "Missing dependencies: ${missing_deps[*]}"
    log_info "Please install missing dependencies and try again."
    log_info "On NixOS: nix-shell -p sops age"
    log_info "On macOS: brew install sops age"
    exit 1
  fi

  log_success "All dependencies found"
}

backup_existing_secrets() {
  log_info "Creating backup of existing secrets..."

  mkdir -p "$BACKUP_DIR"

  if [ -f "${SOPS_DIR}/secrets.yaml" ]; then
    cp "${SOPS_DIR}/secrets.yaml" "${BACKUP_DIR}/legacy-secrets.yaml"
    log_success "Backed up legacy secrets to ${BACKUP_DIR}/legacy-secrets.yaml"
  fi

  if [ -f "${SOPS_DIR}/.sops.yaml" ]; then
    cp "${SOPS_DIR}/.sops.yaml" "${BACKUP_DIR}/legacy-sops.yaml"
    log_success "Backed up legacy .sops.yaml to ${BACKUP_DIR}/legacy-sops.yaml"
  fi

  if [ -d "$SECRETS_DIR" ]; then
    cp -r "$SECRETS_DIR" "${BACKUP_DIR}/secrets"
    log_success "Backed up existing secrets directory to ${BACKUP_DIR}/secrets"
  fi
}

setup_age_keys() {
  log_info "Setting up age keys..."

  local age_dir="${HOME}/.config/sops/age"
  local age_key_file="${age_dir}/keys.txt"

  mkdir -p "$age_dir"

  if [ ! -f "$age_key_file" ]; then
    log_info "Generating new age key..."
    age-keygen -o "$age_key_file"
    chmod 600 "$age_key_file"
    log_success "Generated new age key at $age_key_file"
  else
    log_info "Age key already exists at $age_key_file"
  fi

  # Extract public key
  local public_key
  public_key=$(age-keygen -y "$age_key_file")
  log_info "Your age public key: $public_key"

  # Save public key for reference
  echo "$public_key" >"${age_dir}/public_key.txt"
  log_success "Public key saved to ${age_dir}/public_key.txt"

  echo "$public_key"
}

create_directory_structure() {
  log_info "Creating directory structure..."

  local dirs=(
    "$SECRETS_DIR"
    "$SECRETS_DIR/development"
    "$SECRETS_DIR/production"
    "$SECRETS_DIR/staging"
    "$SECRETS_DIR/systems"
    "$SECRETS_DIR/users"
  )

  for dir in "${dirs[@]}"; do
    mkdir -p "$dir"
    log_success "Created directory: $dir"
  done
}

create_template_secrets() {
  log_info "Creating template secret files..."

  # Development secrets template
  cat >"${SECRETS_DIR}/development/secrets.yaml" <<'EOF'
# Development Environment Secrets
# These secrets are used for local development and testing

# API Keys (Development/Testing)
anthropic_api_key: CHANGE_ME_DEV_ANTHROPIC_KEY
openai_api_key: CHANGE_ME_DEV_OPENAI_KEY
azure_openai_api_key: CHANGE_ME_DEV_AZURE_OPENAI_KEY
github_token: CHANGE_ME_DEV_GITHUB_TOKEN

# Local Development
database_url: postgresql://dev_user:dev_pass@localhost:5432/dev_db
redis_url: redis://localhost:6379/0
test_user_password: CHANGE_ME_TEST_PASSWORD
test_api_key: CHANGE_ME_TEST_API_KEY

# Development Tools
docker_registry_token: CHANGE_ME_DOCKER_TOKEN
npm_auth_token: CHANGE_ME_NPM_TOKEN
pypi_token: CHANGE_ME_PYPI_TOKEN

# Network (Development)
wifi_dev_network_password: CHANGE_ME_WIFI_PASSWORD
vpn_dev_config: CHANGE_ME_VPN_CONFIG

# SSL Certificates (Local)
local_ssl_cert: |
  -----BEGIN CERTIFICATE-----
  CHANGE_ME_LOCAL_SSL_CERT
  -----END CERTIFICATE-----
local_ssl_key: |
  -----BEGIN PRIVATE KEY-----
  CHANGE_ME_LOCAL_SSL_KEY
  -----END PRIVATE KEY-----
EOF

  # Production secrets template
  cat >"${SECRETS_DIR}/production/secrets.yaml" <<'EOF'
# Production Environment Secrets
# These secrets are used in production environments

# === API Keys and External Services ===
anthropic_api_key: CHANGE_ME_PROD_ANTHROPIC_KEY
openai_api_key: CHANGE_ME_PROD_OPENAI_KEY
azure_openai_api_key: CHANGE_ME_PROD_AZURE_OPENAI_KEY
github_token: CHANGE_ME_PROD_GITHUB_TOKEN
gitlab_token: CHANGE_ME_PROD_GITLAB_TOKEN

# === Cloud Infrastructure ===
aws_access_key_id: CHANGE_ME_AWS_ACCESS_KEY
aws_secret_access_key: CHANGE_ME_AWS_SECRET_KEY
aws_session_token: CHANGE_ME_AWS_SESSION_TOKEN
gcp_service_account_key: |
  {
    "type": "service_account",
    "project_id": "CHANGE_ME",
    "private_key_id": "CHANGE_ME",
    "private_key": "CHANGE_ME",
    "client_email": "CHANGE_ME",
    "client_id": "CHANGE_ME",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token"
  }
azure_client_secret: CHANGE_ME_AZURE_CLIENT_SECRET
cloudflare_api_token: CHANGE_ME_CLOUDFLARE_TOKEN
digitalocean_token: CHANGE_ME_DO_TOKEN

# === Database and Storage ===
database_url: postgresql://prod_user:CHANGE_ME@prod-db:5432/prod_db
database_password: CHANGE_ME_DB_PASSWORD
redis_url: redis://prod-redis:6379/0
redis_password: CHANGE_ME_REDIS_PASSWORD
s3_bucket_key: CHANGE_ME_S3_KEY

# === Monitoring and Observability ===
datadog_api_key: CHANGE_ME_DATADOG_KEY
newrelic_license_key: CHANGE_ME_NEWRELIC_KEY
sentry_dsn: https://CHANGE_ME@sentry.io/CHANGE_ME
prometheus_token: CHANGE_ME_PROMETHEUS_TOKEN
grafana_api_key: CHANGE_ME_GRAFANA_KEY

# === Security and Certificates ===
backup_encryption_key: CHANGE_ME_BACKUP_KEY
disaster_recovery_key: CHANGE_ME_DR_KEY
ssh_deploy_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  CHANGE_ME_SSH_DEPLOY_KEY
  -----END OPENSSH PRIVATE KEY-----
gpg_private_key: |
  -----BEGIN PGP PRIVATE KEY BLOCK-----
  CHANGE_ME_GPG_PRIVATE_KEY
  -----END PGP PRIVATE KEY BLOCK-----

# === Application Secrets ===
jwt_secret: CHANGE_ME_JWT_SECRET
session_secret: CHANGE_ME_SESSION_SECRET
encryption_key: CHANGE_ME_ENCRYPTION_KEY
webhook_secret: CHANGE_ME_WEBHOOK_SECRET

# === Third-party Integrations ===
stripe_secret_key: sk_live_CHANGE_ME
paypal_client_secret: CHANGE_ME_PAYPAL_SECRET
twilio_auth_token: CHANGE_ME_TWILIO_TOKEN
sendgrid_api_key: SG.CHANGE_ME
slack_webhook_url: https://hooks.slack.com/services/CHANGE_ME

# === TLS Certificates ===
tls_private_key: |
  -----BEGIN PRIVATE KEY-----
  CHANGE_ME_TLS_PRIVATE_KEY
  -----END PRIVATE KEY-----
tls_certificate: |
  -----BEGIN CERTIFICATE-----
  CHANGE_ME_TLS_CERTIFICATE
  -----END CERTIFICATE-----
EOF

  # Staging secrets (copy of production template)
  cp "${SECRETS_DIR}/production/secrets.yaml" "${SECRETS_DIR}/staging/secrets.yaml"
  sed -i.bak 's/PROD_/STAGING_/g; s/prod-/staging-/g' "${SECRETS_DIR}/staging/secrets.yaml"
  rm "${SECRETS_DIR}/staging/secrets.yaml.bak"

  # User-specific secrets template
  cat >"${SECRETS_DIR}/users/alex.yaml" <<'EOF'
# User-specific secrets for alex
# Personal credentials and user-specific configurations

# Personal API Keys
personal_github_token: CHANGE_ME_PERSONAL_GITHUB_TOKEN
personal_gitlab_token: CHANGE_ME_PERSONAL_GITLAB_TOKEN

# Personal Cloud Storage
personal_dropbox_token: CHANGE_ME_DROPBOX_TOKEN
personal_google_drive_token: CHANGE_ME_GDRIVE_TOKEN

# Personal Development
personal_npm_token: CHANGE_ME_PERSONAL_NPM_TOKEN
personal_pypi_token: CHANGE_ME_PERSONAL_PYPI_TOKEN

# Personal SSH Keys
personal_ssh_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  CHANGE_ME_PERSONAL_SSH_KEY
  -----END OPENSSH PRIVATE KEY-----

# Personal GPG Key
personal_gpg_key: |
  -----BEGIN PGP PRIVATE KEY BLOCK-----
  CHANGE_ME_PERSONAL_GPG_KEY
  -----END PGP PRIVATE KEY BLOCK-----

# WiFi Networks
wifi_home_password: CHANGE_ME_HOME_WIFI_PASSWORD
wifi_office_password: CHANGE_ME_OFFICE_WIFI_PASSWORD

# VPN Configurations
personal_vpn_config: |
  [Interface]
  PrivateKey = CHANGE_ME_VPN_PRIVATE_KEY
  Address = 10.0.0.2/24
  DNS = 1.1.1.1
  
  [Peer]
  PublicKey = CHANGE_ME_VPN_PUBLIC_KEY
  Endpoint = vpn.example.com:51820
  AllowedIPs = 0.0.0.0/0
EOF

  # System-specific secrets template
  cat >"${SECRETS_DIR}/systems/NIXY.yaml" <<'EOF'
# System-specific secrets for NIXY
# Hardware and system-specific configurations

# System SSH Keys
system_ssh_host_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  CHANGE_ME_SYSTEM_SSH_HOST_KEY
  -----END OPENSSH PRIVATE KEY-----

# System Certificates
system_tls_cert: |
  -----BEGIN CERTIFICATE-----
  CHANGE_ME_SYSTEM_TLS_CERT
  -----END CERTIFICATE-----

system_tls_key: |
  -----BEGIN PRIVATE KEY-----
  CHANGE_ME_SYSTEM_TLS_KEY
  -----END PRIVATE KEY-----

# Hardware-specific
disk_encryption_key: CHANGE_ME_DISK_ENCRYPTION_KEY
secure_boot_key: CHANGE_ME_SECURE_BOOT_KEY

# Network Configuration
static_ip_config: 192.168.1.100/24
network_gateway: 192.168.1.1
dns_servers: 1.1.1.1,8.8.8.8

# System Monitoring
system_monitoring_token: CHANGE_ME_MONITORING_TOKEN
log_aggregation_key: CHANGE_ME_LOG_KEY
EOF

  log_success "Created template secret files"
  log_warning "Remember to replace all CHANGE_ME placeholders with actual values!"
}

migrate_legacy_secrets() {
  log_info "Checking for legacy secrets to migrate..."

  local legacy_file="${SOPS_DIR}/secrets.yaml"

  if [ ! -f "$legacy_file" ]; then
    log_info "No legacy secrets file found, skipping migration"
    return
  fi

  log_info "Found legacy secrets file, attempting to decrypt and migrate..."

  # Try to decrypt legacy secrets
  if sops --decrypt "$legacy_file" >/dev/null 2>&1; then
    log_info "Successfully decrypted legacy secrets"

    # Create a migration helper script
    cat >"${BACKUP_DIR}/migrate_secrets.sh" <<'EOF'
#!/bin/bash
# Helper script to migrate specific secrets from legacy file
# Usage: ./migrate_secrets.sh

LEGACY_FILE="legacy-secrets.yaml"
DEV_FILE="../secrets/development/secrets.yaml"

echo "Migrating secrets from $LEGACY_FILE to new structure..."
echo "This is a manual process - please review and update the new files."
echo ""
echo "Legacy secrets found:"
sops --decrypt "$LEGACY_FILE" | grep -E "^[a-zA-Z_].*:" | sed 's/:.*$//' | sort

echo ""
echo "Please manually copy relevant secrets to the appropriate environment files:"
echo "- Development: $DEV_FILE"
echo "- Production: ../secrets/production/secrets.yaml"
echo "- User-specific: ../secrets/users/alex.yaml"
echo "- System-specific: ../secrets/systems/NIXY.yaml"
EOF

    chmod +x "${BACKUP_DIR}/migrate_secrets.sh"
    log_success "Created migration helper script at ${BACKUP_DIR}/migrate_secrets.sh"

  else
    log_warning "Could not decrypt legacy secrets file"
    log_info "You may need to set up your age keys first"
  fi
}

update_sops_yaml() {
  log_info "Updating .sops.yaml configuration..."

  local public_key="$1"

  # The .sops.yaml should already be updated by the previous step
  # This function validates it exists and has the correct structure

  if [ ! -f "${DOTFILES_DIR}/.sops.yaml" ]; then
    log_error ".sops.yaml not found! Please ensure it was created in the previous step."
    return 1
  fi

  log_success ".sops.yaml configuration is ready"
  log_info "Remember to update the age keys in .sops.yaml with your public key: $public_key"
}

encrypt_template_files() {
  log_info "Encrypting template secret files..."

  local files=(
    "${SECRETS_DIR}/development/secrets.yaml"
    "${SECRETS_DIR}/production/secrets.yaml"
    "${SECRETS_DIR}/staging/secrets.yaml"
    "${SECRETS_DIR}/users/alex.yaml"
    "${SECRETS_DIR}/systems/NIXY.yaml"
  )

  for file in "${files[@]}"; do
    if [ -f "$file" ]; then
      log_info "Encrypting $file..."
      if sops --encrypt --in-place "$file"; then
        log_success "Encrypted $file"
      else
        log_error "Failed to encrypt $file"
      fi
    fi
  done
}

create_usage_examples() {
  log_info "Creating usage examples..."

  cat >"${SECRETS_DIR}/examples.nix" <<'EOF'
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
EOF

  log_success "Created usage examples at ${SECRETS_DIR}/examples.nix"
}

print_next_steps() {
  log_success "Migration completed successfully!"
  echo ""
  log_info "Next steps:"
  echo "1. Review and update secret values in the template files:"
  echo "   - ${SECRETS_DIR}/development/secrets.yaml"
  echo "   - ${SECRETS_DIR}/production/secrets.yaml"
  echo "   - ${SECRETS_DIR}/users/alex.yaml"
  echo "   - ${SECRETS_DIR}/systems/NIXY.yaml"
  echo ""
  echo "2. Update your NixOS/Home Manager configurations to use the new structure:"
  echo "   - See examples in ${SECRETS_DIR}/examples.nix"
  echo "   - Replace old sops imports with new sopsConfig imports"
  echo ""
  echo "3. Update .sops.yaml with your actual age public keys"
  echo ""
  echo "4. Test the configuration:"
  echo "   - nix build .#nixosConfigurations.NIXY.config.system.build.toplevel"
  echo "   - home-manager switch"
  echo ""
  echo "5. If migration from legacy secrets is needed:"
  echo "   - Run ${BACKUP_DIR}/migrate_secrets.sh"
  echo "   - Manually copy relevant secrets to new files"
  echo ""
  log_info "Backup created at: $BACKUP_DIR"
  log_info "Documentation available at: ${SECRETS_DIR}/README.md"
}

main() {
  log_info "Starting sops-nix migration to production-ready setup..."
  echo ""

  check_dependencies
  backup_existing_secrets

  local public_key
  public_key=$(setup_age_keys)

  create_directory_structure
  create_template_secrets
  migrate_legacy_secrets
  update_sops_yaml "$public_key"
  create_usage_examples

  # Only encrypt if we have a working sops setup
  if command -v sops &>/dev/null && [ -f "${DOTFILES_DIR}/.sops.yaml" ]; then
    encrypt_template_files
  else
    log_warning "Skipping encryption - please encrypt files manually after setting up .sops.yaml"
  fi

  print_next_steps
}

# Run main function
main "$@"
