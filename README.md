# aio-harbor-registry-cache
Managed by github-org-manager

## Overview
An all-in-one Harbor registry cache setup with OpenTofu configuration for managing container registry proxies. Supports both CORE and REPLICA deployment modes for distributed caching architectures.

## Architecture

### CORE Mode
- Points directly to upstream registries (docker.io, quay.io, ghcr.io, etc.)
- Serves as the primary cache tier
- Configured with `TF_VAR_harbor_registry_mode="CORE"`

### REPLICA Mode  
- Points to a CORE Harbor instance instead of upstream registries
- Creates a tiered caching architecture for reduced bandwidth and improved performance
- Configured with `TF_VAR_harbor_registry_mode="REPLICA"`

## Usage

### Quick Start (Local Development)
```bash
# Use default local environment (CORE mode, HTTP-only)
./glueops-test.sh
```

### Production Deployments
```bash
# Deploy CORE Harbor instance
./glueops-test.sh --env-file=core.env.example

# Deploy REPLICA Harbor instance
./glueops-test.sh --env-file=replica.env.example

# Use custom environment file
./glueops-test.sh --env-file=my-production.env
```

### Development/CI Environments
```bash
# Local development
./glueops-test.sh --env=local

# GitHub Actions CI
./glueops-test.sh --env=github
```

## Configuration

### Environment Files
- `config/local.env` - Local development settings (ignored in git)
- `config/github.env` - GitHub Actions CI settings (ignored in git)
- `config/core.env.example` - CORE Harbor template
- `config/replica.env.example` - REPLICA Harbor template

### Setting Up New Environments
1. Copy the appropriate template file:
   ```bash
   # For CORE Harbor
   cp config/core.env.example config/my-core.env
   
   # For REPLICA Harbor
   cp config/replica.env.example config/my-replica.env
   ```
2. Edit the new file with your environment-specific values
3. Use with: `./glueops-test.sh --env-file=my-core.env`

### Required Environment Variables
- `HARBOR_HOSTNAME` - Harbor server hostname
- `HARBOR_DATA_VOLUME_PATH` - Data volume path
- `HARBOR_HTTPS_ENABLED` - Enable/disable HTTPS (true/false)
- `HARBOR_NGINX_CERT_LOCATION` - SSL certificate location (if HTTPS enabled)
- `HARBOR_NGINX_KEY_LOCATION` - SSL private key location (if HTTPS enabled)
- `HARBOR_URL` - Harbor server URL for OpenTofu
- `TF_VAR_harbor_registry_mode` - Registry mode: "CORE" or "REPLICA"
- `TF_VAR_harbor_core_hostname` - CORE Harbor hostname (required for REPLICA mode)

### Optional Environment Variables
- `CREATE_LOCAL_CERTS` - Generate local self-signed certificates (true/false, default: false)
- `TF_VAR_GOOGLE_OIDC_CLIENT_ID` - Google OIDC client ID
- `TF_VAR_GOOGLE_OIDC_CLIENT_SECRET` - Google OIDC client secret

## HTTPS Configuration
The setup supports both HTTP and HTTPS modes:

### HTTP Mode (HARBOR_HTTPS_ENABLED=false)
- Perfect for local development and testing
- No certificate management required
- Harbor HTTPS section is automatically removed from configuration

### HTTPS Mode (HARBOR_HTTPS_ENABLED=true)
- Required for production deployments
- Supports both generated and custom certificates

#### Certificate Options:
1. **Auto-generated certificates** (`CREATE_LOCAL_CERTS=true`):
   - Self-signed certificates for localhost
   - Suitable for development/testing

2. **Custom certificates** (`CREATE_LOCAL_CERTS=false`):
   - Use existing certificates specified by environment variables
   - Required for production with real domain names

## Registry Proxy Projects
The script automatically creates proxy projects for major registries:

### CORE Mode Endpoints:
- Docker Hub: `https://hub.docker.com`
- GitHub Container Registry: `https://ghcr.io`
- Quay.io: `https://quay.io`
- Google Container Registry: `https://gcr.io`
- AWS Public ECR: `https://public.ecr.aws`

### REPLICA Mode Endpoints:
- Docker Hub: `https://{CORE_HOSTNAME}/proxy-docker-io`
- GitHub Container Registry: `https://{CORE_HOSTNAME}/proxy-ghcr-io`
- Quay.io: `https://{CORE_HOSTNAME}/proxy-quay-io`
- Google Container Registry: `https://{CORE_HOSTNAME}/proxy-gcr-io`
- AWS Public ECR: `https://{CORE_HOSTNAME}/proxy-public-ecr-aws`
