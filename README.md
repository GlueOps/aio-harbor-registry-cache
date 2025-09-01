# aio-harbor-registry-cache

## Overview
An all-in-one Harbor registry cache setup with OpenTofu configuration for managing container registry proxies. Supports both CORE and REPLICA deployment modes for distributed caching architectures. More details about the implementation can be found here: https://glueops.github.io/aio-harbor-registry-cache/

## Architecture

This project implements a tiered Harbor registry cache architecture with both CORE and REPLICA deployment modes for distributed caching across multiple data centers.

```mermaid
graph TB
    subgraph "External Registries"
        DockerHub[Docker Hub<br/>hub.docker.com]
        GHCR[GitHub Container Registry<br/>ghcr.io]
        Quay[Quay.io<br/>quay.io]
        GCR[Google Container Registry<br/>gcr.io]
        ECR[AWS Public ECR<br/>public.ecr.aws]
    end

    subgraph "Data Center 1 - CORE Harbor"
        subgraph "Core Node"
            CoreNginx[Nginx Proxy<br/>Port 443 → 8443<br/>TLS 1.3 Termination]
            CoreHarbor[Harbor Core<br/>Port 8443<br/>180-day cache]
            CoreVolume[(Persistent Storage<br/>180-day retention)]
        end
        CoreNginx --> CoreHarbor
        CoreHarbor --> CoreVolume
    end

    subgraph "Data Center 2 - CORE Harbor"
        subgraph "Core Node 2"
            Core2Nginx[Nginx Proxy<br/>Port 443 → 8443<br/>TLS 1.3 Termination]
            Core2Harbor[Harbor Core<br/>Port 8443<br/>180-day cache]
            Core2Volume[(Persistent Storage<br/>180-day retention)]
        end
        Core2Nginx --> Core2Harbor
        Core2Harbor --> Core2Volume
    end

    subgraph "Regional Location 1 - REPLICA Harbor"
        subgraph "Replica Node"
            ReplicaNginx[Nginx Proxy<br/>Port 443 → 8443<br/>Path Rewriting<br/>TLS 1.3 Termination]
            ReplicaHarbor[Harbor Replica<br/>Port 8443<br/>14-day cache]
            ReplicaVolume[(Persistent Storage<br/>14-day retention)]
        end
        ReplicaNginx --> ReplicaHarbor
        ReplicaHarbor --> ReplicaVolume
    end

    subgraph "Regional Location 2 - REPLICA Harbor"
        subgraph "Replica Node 2"
            Replica2Nginx[Nginx Proxy<br/>Port 443 → 8443<br/>Path Rewriting<br/>TLS 1.3 Termination]
            Replica2Harbor[Harbor Replica<br/>Port 8443<br/>14-day cache]
            Replica2Volume[(Persistent Storage<br/>14-day retention)]
        end
        Replica2Nginx --> Replica2Harbor
        Replica2Harbor --> Replica2Volume
    end

    subgraph "DNS Layer"
        DNSCore[DNS Round Robin<br/>harbor-core.domain.com<br/>Geo-based routing]
        DNSReplica[DNS Round Robin<br/>harbor-replica-region.domain.com<br/>Health checks]
    end

    subgraph "Clients"
        K8sCluster[Kubernetes Clusters]
        CI[CI/CD Pipelines]
        Developers[Developer Workstations]
    end

    subgraph "OIDC & Authentication"
        GoogleOIDC[Google OIDC<br/>Admin Authentication]
        LocalOIDC[Local OIDC Testing<br/>⚠️ Challenging with devtunnels]
        VPSOIDC[VPS OIDC Testing<br/>✅ Recommended approach]
    end

    %% External registry connections (CORE only)
    CoreHarbor -.->|Proxy Cache| DockerHub
    CoreHarbor -.->|Proxy Cache| GHCR
    CoreHarbor -.->|Proxy Cache| Quay
    CoreHarbor -.->|Proxy Cache| GCR
    CoreHarbor -.->|Proxy Cache| ECR
    
    Core2Harbor -.->|Proxy Cache| DockerHub
    Core2Harbor -.->|Proxy Cache| GHCR
    Core2Harbor -.->|Proxy Cache| Quay
    Core2Harbor -.->|Proxy Cache| GCR
    Core2Harbor -.->|Proxy Cache| ECR

    %% REPLICA connections (point to CORE only)
    ReplicaHarbor -.->|Proxy Cache<br/>No direct upstream| CoreHarbor
    ReplicaHarbor -.->|Proxy Cache<br/>No direct upstream| Core2Harbor
    
    Replica2Harbor -.->|Proxy Cache<br/>No direct upstream| CoreHarbor
    Replica2Harbor -.->|Proxy Cache<br/>No direct upstream| Core2Harbor

    %% DNS routing
    DNSCore --> CoreNginx
    DNSCore --> Core2Nginx
    DNSReplica --> ReplicaNginx
    DNSReplica --> Replica2Nginx

    %% Client connections
    K8sCluster --> DNSCore
    K8sCluster --> DNSReplica
    CI --> DNSCore
    CI --> DNSReplica
    Developers --> DNSCore
    Developers --> DNSReplica

    %% OIDC connections
    GoogleOIDC -.->|Admin Access| CoreHarbor
    GoogleOIDC -.->|Admin Access| Core2Harbor
    GoogleOIDC -.->|Admin Access| ReplicaHarbor
    GoogleOIDC -.->|Admin Access| Replica2Harbor
    
    LocalOIDC -.->|❌ Difficult| CoreHarbor
    VPSOIDC -.->|✅ Works Well| CoreHarbor

    classDef coreNode fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef replicaNode fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef externalRegistry fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef nginx fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef dns fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef client fill:#f1f8e9,stroke:#33691e,stroke-width:2px
    classDef oidc fill:#fff8e1,stroke:#f57f17,stroke-width:2px
    classDef warning fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef success fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px

    class CoreHarbor,Core2Harbor,CoreVolume,Core2Volume coreNode
    class ReplicaHarbor,Replica2Harbor,ReplicaVolume,Replica2Volume replicaNode
    class DockerHub,GHCR,Quay,GCR,ECR externalRegistry
    class CoreNginx,Core2Nginx,ReplicaNginx,Replica2Nginx nginx
    class DNSCore,DNSReplica dns
    class K8sCluster,CI,Developers client
    class GoogleOIDC,LocalOIDC,VPSOIDC oidc
    class LocalOIDC warning
    class VPSOIDC success
```

### CORE Mode
- Points directly to upstream registries (docker.io, quay.io, ghcr.io, etc.)
- Serves as the primary cache tier with 180-day retention
- Deployed across multiple data centers for high availability
- Configured with `TF_VAR_harbor_registry_mode="CORE"`

### REPLICA Mode  
- Points to CORE Harbor instances instead of upstream registries
- Creates a tiered caching architecture for reduced bandwidth and improved performance
- Maintains a 14-day cache for regional distribution
- Configured with `TF_VAR_harbor_registry_mode="REPLICA"`

### Nginx Proxy Layer
Each Harbor deployment includes an Nginx proxy that serves multiple critical functions:

- **TLS Termination**: Handles TLS 1.3 encryption and modern security headers
- **Port Translation**: Redirects from standard HTTPS port 443 to Harbor's 8443
- **Path Rewriting** (REPLICA only): Transforms client requests to match Harbor's proxy project structure
- **HTTP to HTTPS Redirect**: Ensures all traffic is encrypted

#### Why Another Nginx?
Harbor includes its own internal nginx, but we add an external nginx layer for several reasons:

1. **Clean Client Interface**: Clients can use standard port 443 instead of Harbor's 8443
2. **URL Path Normalization**: REPLICAs need special path rewriting to work with Harbor's proxy project structure
3. **TLS Configuration Control**: Modern TLS 1.3-only configuration with security headers
4. **Future Extensibility**: Allows for load balancing, additional routing rules, and monitoring

### DNS-Based Load Balancing
The architecture uses DNS for service discovery and load balancing:

- **Geo-based Routing**: Route clients to the nearest available instance
- **Health Checks**: Automatic failover when nodes become unavailable  
- **Round Robin Distribution**: Distribute load across available CORE nodes
- **Cost Effective**: Eliminates need for dedicated load balancers

### OIDC Authentication Challenges

#### Local Development Limitations
Testing OIDC authentication locally presents several challenges:

- **Callback URL Requirements**: OIDC providers require publicly accessible callback URLs
- **Devtunnel Limitations**: While devtunnels provide public URLs, they can be unstable for OIDC flows
- **Certificate Validation**: Self-signed certificates cause OIDC validation issues
- **Port Mapping Complexity**: The nginx proxy layer adds complexity to local OIDC testing

#### Recommended Testing Approach: VPS Deployment
**✅ Best Practice**: Deploy to a VPS with proper DNS and certificates for OIDC testing because:

- **Stable Public URLs**: Real domain names work reliably with OIDC providers
- **Valid TLS Certificates**: Let's Encrypt or other CA-issued certificates prevent validation issues  
- **Consistent Networking**: No tunnel instability or port mapping complications
- **Production Parity**: Testing environment matches production deployment closely

#### OIDC Configuration
The system supports Google OIDC for administrative access:
- `TF_VAR_GOOGLE_OIDC_CLIENT_ID`: Google OAuth client ID
- `TF_VAR_GOOGLE_OIDC_CLIENT_SECRET`: Google OAuth client secret
- Authentication is disabled for image pulls to ensure frictionless cluster bootstrapping

## Server Requirements

- Debian 12
- Docker installed:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt update -y
sudo apt install -y git zip unzip
git clone https://github.com/GlueOps/aio-harbor-registry-cache.git
cd aio-harbor-registry-cache
```

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



## OIDC Authentication & Testing

### Local Testing Challenges
Testing OIDC authentication locally is challenging due to several technical limitations:

1. **Public Callback URLs Required**: OIDC providers (like Google) require publicly accessible callback URLs for the OAuth flow
2. **Devtunnel Instability**: While devtunnels can provide public URLs, they can be unstable and cause OIDC flow interruptions
3. **Certificate Validation Issues**: Self-signed certificates used in local development cause OIDC provider validation failures
4. **Complex Port Mapping**: The nginx proxy layer (443 → 8443) adds complexity to local OIDC callback URL configuration

### Recommended Approach: VPS Testing
**✅ Best Practice**: For OIDC testing, deploy to a VPS with proper DNS and certificates:

- **Stable Public Domain**: Real domain names work reliably with OIDC providers
- **Valid TLS Certificates**: Use Let's Encrypt or CA-issued certificates to prevent validation issues
- **Production Parity**: Testing environment closely matches production deployment
- **Reliable Networking**: No tunnel instability or complex port mapping

### OIDC Configuration
Set these environment variables for Google OIDC integration:
```bash
export TF_VAR_GOOGLE_OIDC_CLIENT_ID="your-client-id.apps.googleusercontent.com"
export TF_VAR_GOOGLE_OIDC_CLIENT_SECRET="your-client-secret"
```

**Note**: Image pulls remain authentication-free to ensure frictionless cluster bootstrapping, while administrative access uses OIDC. 