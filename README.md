# aio-harbor-registry-cache

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

### Development/CI Environments
```bash
# Local development
./setup.sh --env=local

# GitHub Actions CI
./setup.sh --env=github
```

### Production Deployments
```bash
# Deploy CORE Harbor instance
./setup.sh --env-file=core.env.example

# Deploy REPLICA Harbor instance
./setup.sh --env-file=replica.env.example

# Use custom environment file
./setup.sh --env-file=my-production.env
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
3. Use with: `./setup.sh --env-file=my-core.env`

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
