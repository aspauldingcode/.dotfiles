# 🚀 Deployment Guide

This guide covers deployment strategies, production considerations, and operational procedures for our Nix flake configuration.

## Table of Contents

- [Deployment Overview](#deployment-overview)
- [Environment Management](#environment-management)
- [Production Deployment](#production-deployment)
- [Staging Deployment](#staging-deployment)
- [Development Deployment](#development-deployment)
- [Multi-System Deployment](#multi-system-deployment)
- [Rollback Procedures](#rollback-procedures)
- [Monitoring and Health Checks](#monitoring-and-health-checks)
- [Automation and CI/CD](#automation-and-cicd)

## Deployment Overview

### Deployment Architecture

Our deployment system supports multiple environments and systems:

```
Production Environment
├── NIXY (macOS Workstation)
├── NIXSTATION64 (Linux Server)
└── NIXY2 (ARM Linux)

Staging Environment
├── NIXY-staging
└── Test Systems

Development Environment
├── Local Development
└── Feature Branches
```

### Deployment Types

1. **System Deployment**: Full system configuration updates
2. **User Deployment**: Home Manager configuration updates
3. **Service Deployment**: Individual service updates
4. **Secret Deployment**: Encrypted secrets management
5. **Emergency Deployment**: Critical security updates

## Environment Management

### Environment Configuration

#### Production Environment
```bash
# Set production environment
export NIX_FLAKE_ENV="production"
export SOPS_AGE_KEY_FILE="~/.config/sops/age/production.txt"

# Production-specific settings
export NIX_BUILD_CORES=8
export NIX_MAX_JOBS=4
export NIX_SUBSTITUTERS="https://cache.nixos.org https://production.cachix.org"
```

#### Staging Environment
```bash
# Set staging environment
export NIX_FLAKE_ENV="staging"
export SOPS_AGE_KEY_FILE="~/.config/sops/age/staging.txt"

# Staging-specific settings
export NIX_BUILD_CORES=4
export NIX_MAX_JOBS=2
```

#### Development Environment
```bash
# Set development environment
export NIX_FLAKE_ENV="development"
export SOPS_AGE_KEY_FILE="~/.config/sops/age/development.txt"

# Development-specific settings
export NIX_BUILD_CORES=2
export NIX_MAX_JOBS=1
export NIX_FAST_BUILD=true
```

### Environment Switching

```bash
# Switch to production
./scripts/system-manager.sh set-environment production

# Switch to staging
./scripts/system-manager.sh set-environment staging

# Switch to development
./scripts/system-manager.sh set-environment development

# Verify current environment
./scripts/system-manager.sh current-environment
```

## Production Deployment

### Pre-Deployment Checklist

1. **Code Review and Approval**:
   ```bash
   # Ensure all changes are reviewed
   git log --oneline origin/main..HEAD
   
   # Check for required approvals
   gh pr view --json reviewDecision
   ```

2. **Testing Validation**:
   ```bash
   # Run comprehensive tests
   ./scripts/test-framework.sh --environment production
   
   # Validate secrets
   ./scripts/secrets-manager.sh validate --environment production
   
   # Security scan
   ./scripts/test-framework.sh --suite security
   ```

3. **Backup Current State**:
   ```bash
   # Backup current configuration
   ./scripts/system-manager.sh backup NIXY
   
   # Backup secrets
   ./scripts/secrets-manager.sh backup --environment production
   ```

### Production Deployment Process

#### Step 1: Prepare Deployment
```bash
# Set production environment
export NIX_FLAKE_ENV="production"

# Update flake inputs (if needed)
nix flake update

# Pre-build configurations
./scripts/system-manager.sh build production NIXY
./scripts/system-manager.sh build production NIXSTATION64
```

#### Step 2: Deploy to Production Systems
```bash
# Deploy to primary system
./scripts/system-manager.sh deploy production NIXY

# Deploy to secondary systems
./scripts/system-manager.sh deploy production NIXSTATION64
./scripts/system-manager.sh deploy production NIXY2
```

#### Step 3: Verify Deployment
```bash
# Health check all systems
./scripts/system-manager.sh health-check NIXY
./scripts/system-manager.sh health-check NIXSTATION64
./scripts/system-manager.sh health-check NIXY2

# Verify services
./scripts/system-manager.sh status NIXY --services
```

#### Step 4: Post-Deployment Tasks
```bash
# Update monitoring
./scripts/system-manager.sh update-monitoring

# Generate deployment report
./scripts/system-manager.sh deployment-report

# Tag successful deployment
git tag "production-$(date +%Y%m%d-%H%M%S)"
git push origin --tags
```

### Production Deployment Script

```bash
#!/bin/bash
# scripts/deploy-production.sh

set -euo pipefail

SYSTEMS=("NIXY" "NIXSTATION64" "NIXY2")
ENVIRONMENT="production"

echo "🚀 Starting production deployment..."

# Pre-deployment checks
echo "📋 Running pre-deployment checks..."
./scripts/test-framework.sh --environment production --quick
./scripts/secrets-manager.sh validate --environment production

# Backup current state
echo "💾 Creating backups..."
for system in "${SYSTEMS[@]}"; do
    ./scripts/system-manager.sh backup "$system"
done

# Deploy to each system
echo "🔄 Deploying to production systems..."
for system in "${SYSTEMS[@]}"; do
    echo "Deploying to $system..."
    ./scripts/system-manager.sh deploy production "$system"
    
    echo "Running health check for $system..."
    ./scripts/system-manager.sh health-check "$system"
done

# Post-deployment verification
echo "✅ Running post-deployment verification..."
./scripts/system-manager.sh verify-deployment production

echo "🎉 Production deployment completed successfully!"
```

## Staging Deployment

### Staging Environment Setup

```bash
# Initialize staging environment
./scripts/system-manager.sh init-environment staging

# Create staging secrets
./scripts/secrets-manager.sh create staging staging-secrets

# Deploy staging configuration
./scripts/system-manager.sh deploy staging NIXY-staging
```

### Staging Deployment Process

```bash
# Deploy to staging
./scripts/deploy-staging.sh

# Run staging tests
./scripts/test-framework.sh --environment staging

# Performance testing
./scripts/test-framework.sh --suite performance --environment staging

# Load testing (if applicable)
./scripts/load-test.sh --environment staging
```

### Staging Validation

```bash
# Validate staging deployment
./scripts/system-manager.sh validate staging

# Compare with production
./scripts/system-manager.sh diff production staging

# Generate staging report
./scripts/system-manager.sh staging-report
```

## Development Deployment

### Local Development Deployment

```bash
# Quick development deployment
./scripts/system-manager.sh deploy development NIXY --fast

# Development with live reload
./scripts/system-manager.sh deploy development NIXY --watch

# Test specific changes
./scripts/system-manager.sh deploy development NIXY --dry-run
```

### Feature Branch Deployment

```bash
# Deploy feature branch
git checkout feature/new-feature
./scripts/system-manager.sh deploy development NIXY --branch feature/new-feature

# Test feature
./scripts/test-framework.sh --suite integration

# Cleanup feature deployment
./scripts/system-manager.sh cleanup development NIXY
```

## Multi-System Deployment

### Parallel Deployment

```bash
# Deploy to multiple systems in parallel
./scripts/system-manager.sh deploy-parallel production NIXY NIXSTATION64 NIXY2

# Monitor parallel deployment
./scripts/system-manager.sh monitor-deployment
```

### Rolling Deployment

```bash
# Rolling deployment with health checks
./scripts/deploy-rolling.sh production NIXY NIXSTATION64 NIXY2

# Rolling deployment script example:
#!/bin/bash
for system in "$@"; do
    echo "Deploying to $system..."
    ./scripts/system-manager.sh deploy production "$system"
    
    echo "Health check for $system..."
    if ! ./scripts/system-manager.sh health-check "$system"; then
        echo "Health check failed for $system, stopping deployment"
        exit 1
    fi
    
    echo "Waiting 30 seconds before next deployment..."
    sleep 30
done
```

### Blue-Green Deployment

```bash
# Blue-green deployment for critical systems
./scripts/deploy-blue-green.sh production NIXY

# Blue-green deployment process:
# 1. Deploy to green environment
# 2. Run comprehensive tests
# 3. Switch traffic to green
# 4. Monitor for issues
# 5. Keep blue as fallback
```

## Rollback Procedures

### Automatic Rollback

```bash
# Automatic rollback on failure
./scripts/system-manager.sh deploy production NIXY --auto-rollback

# Rollback triggers:
# - Health check failure
# - Service startup failure
# - Critical error detection
```

### Manual Rollback

```bash
# List available generations
./scripts/system-manager.sh list-generations NIXY

# Rollback to previous generation
./scripts/system-manager.sh rollback NIXY

# Rollback to specific generation
./scripts/system-manager.sh rollback NIXY --generation 42

# Emergency rollback (fastest)
./scripts/system-manager.sh emergency-rollback NIXY
```

### Rollback Validation

```bash
# Verify rollback success
./scripts/system-manager.sh verify-rollback NIXY

# Test system functionality
./scripts/test-framework.sh --suite smoke --system NIXY

# Generate rollback report
./scripts/system-manager.sh rollback-report NIXY
```

## Monitoring and Health Checks

### Health Check Configuration

```bash
# Configure health checks
./scripts/system-manager.sh configure-health-checks NIXY

# Health check types:
# - System resource usage
# - Service availability
# - Network connectivity
# - Secret accessibility
# - Application functionality
```

### Monitoring Setup

```bash
# Setup monitoring
./scripts/system-manager.sh setup-monitoring

# Monitor deployment
./scripts/system-manager.sh monitor --real-time

# Generate monitoring dashboard
./scripts/system-manager.sh monitoring-dashboard
```

### Alerting Configuration

```bash
# Configure alerts
./scripts/system-manager.sh configure-alerts

# Alert types:
# - Deployment failures
# - Health check failures
# - Performance degradation
# - Security issues
```

### Health Check Examples

```bash
# System health check
check_system_health() {
    # Check disk space
    if [[ $(df / | tail -1 | awk '{print $5}' | sed 's/%//') -gt 90 ]]; then
        echo "ERROR: Disk space critical"
        return 1
    fi
    
    # Check memory usage
    if [[ $(free | grep Mem | awk '{print ($3/$2) * 100.0}') > 90 ]]; then
        echo "ERROR: Memory usage critical"
        return 1
    fi
    
    # Check load average
    if [[ $(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//') > 10 ]]; then
        echo "ERROR: Load average too high"
        return 1
    fi
    
    echo "System health: OK"
    return 0
}

# Service health check
check_service_health() {
    local service=$1
    
    if systemctl is-active --quiet "$service"; then
        echo "Service $service: OK"
        return 0
    else
        echo "ERROR: Service $service not running"
        return 1
    fi
}

# Application health check
check_application_health() {
    local url=$1
    local expected_status=${2:-200}
    
    local status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [[ "$status" == "$expected_status" ]]; then
        echo "Application health: OK"
        return 0
    else
        echo "ERROR: Application health check failed (status: $status)"
        return 1
    fi
}
```

## Automation and CI/CD

### GitHub Actions Deployment

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'staging'
        type: choice
        options:
        - staging
        - production

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'staging' }}
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: cachix/install-nix-action@v18
        with:
          extra_nix_config: |
            experimental-features = nix-command flakes
            
      - uses: cachix/cachix-action@v12
        with:
          name: your-cache
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
          
      - name: Setup SOPS
        run: |
          echo "${{ secrets.SOPS_AGE_KEY }}" > ~/.config/sops/age/keys.txt
          chmod 600 ~/.config/sops/age/keys.txt
          
      - name: Run tests
        run: ./scripts/test-framework.sh --environment ${{ github.event.inputs.environment || 'staging' }}
        
      - name: Deploy
        run: ./scripts/deploy-${{ github.event.inputs.environment || 'staging' }}.sh
        
      - name: Health check
        run: ./scripts/system-manager.sh health-check-all
        
      - name: Notify on failure
        if: failure()
        run: ./scripts/notify-deployment-failure.sh
```

### Automated Deployment Pipeline

```bash
# scripts/automated-deployment.sh
#!/bin/bash

set -euo pipefail

ENVIRONMENT=${1:-staging}
SYSTEMS=${2:-"NIXY"}

echo "🤖 Starting automated deployment to $ENVIRONMENT..."

# Pre-deployment validation
echo "🔍 Running pre-deployment validation..."
./scripts/test-framework.sh --environment "$ENVIRONMENT" --quick

# Security scan
echo "🔒 Running security scan..."
./scripts/test-framework.sh --suite security

# Deploy
echo "🚀 Deploying to $ENVIRONMENT..."
./scripts/system-manager.sh deploy "$ENVIRONMENT" $SYSTEMS

# Post-deployment validation
echo "✅ Running post-deployment validation..."
./scripts/system-manager.sh health-check-all

# Generate report
echo "📊 Generating deployment report..."
./scripts/system-manager.sh deployment-report > "deployment-report-$(date +%Y%m%d-%H%M%S).md"

echo "🎉 Automated deployment completed successfully!"
```

### Deployment Notifications

```bash
# scripts/notify-deployment.sh
#!/bin/bash

ENVIRONMENT=$1
STATUS=$2
SYSTEMS=$3

case $STATUS in
    "started")
        MESSAGE="🚀 Deployment to $ENVIRONMENT started for systems: $SYSTEMS"
        ;;
    "success")
        MESSAGE="✅ Deployment to $ENVIRONMENT completed successfully for systems: $SYSTEMS"
        ;;
    "failed")
        MESSAGE="❌ Deployment to $ENVIRONMENT failed for systems: $SYSTEMS"
        ;;
    "rollback")
        MESSAGE="🔄 Rollback initiated for $ENVIRONMENT systems: $SYSTEMS"
        ;;
esac

# Send to Slack
curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"$MESSAGE\"}" \
    "$SLACK_WEBHOOK_URL"

# Send email notification
echo "$MESSAGE" | mail -s "Deployment Notification" admin@company.com
```

### Deployment Metrics

```bash
# scripts/deployment-metrics.sh
#!/bin/bash

ENVIRONMENT=$1
START_TIME=$2
END_TIME=$3

DURATION=$((END_TIME - START_TIME))

# Calculate metrics
SYSTEMS_DEPLOYED=$(./scripts/system-manager.sh list-deployed "$ENVIRONMENT" | wc -l)
SERVICES_UPDATED=$(./scripts/system-manager.sh list-services-updated "$ENVIRONMENT" | wc -l)
SECRETS_ROTATED=$(./scripts/secrets-manager.sh list-rotated "$ENVIRONMENT" | wc -l)

# Generate metrics report
cat << EOF > "deployment-metrics-$(date +%Y%m%d-%H%M%S).json"
{
  "environment": "$ENVIRONMENT",
  "duration_seconds": $DURATION,
  "systems_deployed": $SYSTEMS_DEPLOYED,
  "services_updated": $SERVICES_UPDATED,
  "secrets_rotated": $SECRETS_ROTATED,
  "timestamp": "$(date -Iseconds)"
}
EOF

# Send metrics to monitoring system
curl -X POST -H 'Content-Type: application/json' \
    -d @"deployment-metrics-$(date +%Y%m%d-%H%M%S).json" \
    "$METRICS_ENDPOINT"
```

---

This deployment guide provides comprehensive coverage of deployment strategies and operational procedures. Customize the scripts and processes according to your specific infrastructure and requirements.