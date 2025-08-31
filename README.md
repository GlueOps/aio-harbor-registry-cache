# aio-harbor-registry-cache
Managed by github-org-manager

## Overview
An all-in-one Harbor registry cache setup with OpenTofu configuration for managing container registry proxies.

## Usage

### Quick Start (Local Development)
```bash
# Use default local environment
./glueops-test.sh
```

### Environment-Specific Usage
```bash
# Local development
./glueops-test.sh --env=local

# GitHub Actions CI
./glueops-test.sh --env=github

# Production deployment
./glueops-test.sh --env=production

# Regional deployments
./glueops-test.sh --env=uswest2
./glueops-test.sh --env=useast1

# Custom environment file
./glueops-test.sh --env-file=my-custom.env
```

## Configuration

### Environment Files
- `config/common.env` - Shared variables across all environments
- `config/local.env` - Local development settings (committed)
- `config/github.env` - GitHub Actions CI settings (committed)
- `config/production.env.example` - Production template
- `config/uswest2.env.example` - US West 2 template  
- `config/useast1.env.example` - US East 1 template

### Setting Up New Environments
1. Copy the appropriate `.env.example` file:
   ```bash
   cp config/production.env.example config/production.env
   ```
2. Edit the new file with your environment-specific values
3. Use with: `./glueops-test.sh --env=production`

### Required Environment Variables
- `HARBOR_HOSTNAME` - Harbor server hostname
- `HARBOR_DATA_VOLUME_PATH` - Data volume path
- `HARBOR_NGINX_CERT_LOCATION` - SSL certificate location
- `HARBOR_NGINX_KEY_LOCATION` - SSL private key location
- `HARBOR_ADMIN_PASSWORD` - Harbor admin password
- `HARBOR_URL` - Harbor server URL for OpenTofu
- `HARBOR_USERNAME` - Harbor username for OpenTofu

### Optional Environment Variables
- `CREATE_LOCAL_CERTS` - Generate local self-signed certificates (true/false, default: false)
  - Set to `true` for local development and testing
  - Set to `false` for production (use real certificates)
- `TF_VAR_GOOGLE_OIDC_CLIENT_ID` - Google OIDC client ID (optional)
- `TF_VAR_GOOGLE_OIDC_CLIENT_SECRET` - Google OIDC client secret (optional)

## Certificate Management
The script supports two modes for SSL certificates:

### Local Development (CREATE_LOCAL_CERTS=true)
- Automatically generates self-signed certificates for localhost
- Certificates are created as `harbor/cert.pem` and `harbor/key.pem`
- Perfect for local testing and development

### Production/Custom Certificates (CREATE_LOCAL_CERTS=false)
- Uses existing certificates specified in environment variables
- Certificate paths defined by `HARBOR_NGINX_CERT_LOCATION` and `HARBOR_NGINX_KEY_LOCATION`
- Validates that certificate files exist before proceeding

## What the Script Does
1. Sets up Harbor registry with SSL certificates (generated or existing)
2. Configures OpenTofu for Harbor management
3. Creates proxy projects for major registries:
   - Docker Hub (`proxy-docker-io`)
   - GitHub Container Registry (`proxy-ghcr-io`)
   - Quay.io (`proxy-quay-io`)
   - AWS Public ECR (`proxy-public-ecr-aws`)
4. Tests proxy functionality by pulling sample images
