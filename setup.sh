#!/usr/bin/env bash
set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --env=ENV_NAME        Use predefined environment config (local, github)"
    echo "  --env-file=FILE       Use custom environment file (absolute or relative to config/)"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --env=github                    # Use GitHub Actions environment"
    echo "  $0 --env-file=core.env.example     # Use CORE Harbor configuration"
    echo "  $0 --env-file=replica.env.example  # Use REPLICA Harbor configuration"
    echo "  $0 --env-file=my-custom.env        # Use custom configuration"
    echo ""
    echo "Available predefined environments:"
    echo "  local       - Local development (CORE mode, HTTP-only)"
    echo "  github      - GitHub Actions CI (CORE mode, HTTP-only)"
    echo ""
    echo "Available example configurations (use with --env-file):"
    echo "  config/core.env.example     - CORE Harbor (points to upstream registries)"
    echo "  config/replica.env.example  - REPLICA Harbor (points to CORE Harbor)"
    echo ""
    echo "Note: Registry mode (CORE/REPLICA) is controlled by TF_VAR_harbor_registry_mode"
    echo "      in your environment configuration file."
    exit 1
}

# Parse command line arguments
ENV_NAME=""
ENV_FILE=""

for arg in "$@"; do
    case $arg in
        --env=*)
            ENV_NAME="${arg#*=}"
            shift
            ;;
        --env-file=*)
            ENV_FILE="${arg#*=}"
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown option: $arg"
            usage
            ;;
    esac
done

# Determine which environment configuration to use
if [ -n "$ENV_FILE" ]; then
    # Custom environment file specified
    if [[ "$ENV_FILE" = /* ]]; then
        # Absolute path
        CONFIG_FILE="$ENV_FILE"
    else
        # Relative path - check if it's in config dir
        CONFIG_FILE="${CONFIG_DIR}/${ENV_FILE}"
    fi
    ENV_NAME="custom"
    echo "Using custom environment file: $CONFIG_FILE"
elif [ -n "$ENV_NAME" ]; then
    # Predefined environment specified
    CONFIG_FILE="${CONFIG_DIR}/${ENV_NAME}.env"
    echo "Using predefined environment: $ENV_NAME"
else
    echo ""
    echo "Error! No environment set!"
    echo ""
    echo ""
    ./setup.sh --help
    exit 1;
fi

# Validate configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE"
    if [ "$ENV_NAME" != "custom" ] && [ "$ENV_NAME" != "local" ] && [ "$ENV_NAME" != "github" ]; then
        echo "HINT: Copy ${CONFIG_DIR}/${ENV_NAME}.env.example to ${CONFIG_DIR}/${ENV_NAME}.env and customize it"
    fi
    exit 1
fi

# Load environment-specific configuration
echo "Loading environment configuration from: $CONFIG_FILE"
source "$CONFIG_FILE"

# Validate required environment variables
REQUIRED_VARS=("HARBOR_HOSTNAME" "HARBOR_DATA_VOLUME_PATH" "HARBOR_NGINX_CERT_LOCATION" "HARBOR_NGINX_KEY_LOCATION" "HARBOR_ADMIN_PASSWORD")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "ERROR: Missing required environment variables:"
    printf '  %s\n' "${MISSING_VARS[@]}"
    echo "Please check your configuration file: $CONFIG_FILE"
    exit 1
fi

echo "Configuration loaded successfully!"
echo "  Harbor Hostname: $HARBOR_HOSTNAME"
echo "  Harbor URL: ${HARBOR_URL:-Not set}"
echo "  HTTPS Enabled: ${HARBOR_HTTPS_ENABLED:-true}"
echo "  Create Local Certs: ${CREATE_LOCAL_CERTS:-false}"
echo "  Environment: $ENV_NAME"
echo ""

cd harbor
docker compose down || true
docker system prune -a -f
rm -rf data/
docker ps -a
sudo chown -R $(whoami) .
git clean -xdf


# Certificate handling
if [ "${CREATE_LOCAL_CERTS}" = "true" ]; then
    echo "Creating local certificates for testing..."
    
    # Build Subject Alternative Names including the actual hostname
    if [ "$HARBOR_HOSTNAME" != "localhost" ] && [ "$HARBOR_HOSTNAME" != "127.0.0.1" ]; then
        SAN_NAMES="DNS:localhost,DNS:${HARBOR_HOSTNAME},IP:127.0.0.1"
        CN_NAME="$HARBOR_HOSTNAME"
    else
        SAN_NAMES="DNS:localhost,IP:127.0.0.1"
        CN_NAME="localhost"
    fi
    
    openssl req \
        -x509 \
        -nodes \
        -newkey rsa:2048 \
        -keyout $HARBOR_NGINX_KEY_LOCATION \
        -out $HARBOR_NGINX_CERT_LOCATION \
        -days 3650 \
        -subj "/CN=${CN_NAME}" \
        -addext "subjectAltName = ${SAN_NAMES}"
    
    echo "Success! Created key.pem and cert.pem with SAN: ${SAN_NAMES}"
else
    echo "Skipping local certificate generation - using certificates from environment config:"
    echo "  Certificate: ${HARBOR_NGINX_CERT_LOCATION}"
    echo "  Private Key: ${HARBOR_NGINX_KEY_LOCATION}"
    
    # Validate that the certificate files exist if not creating local ones
    if [ ! -f "${HARBOR_NGINX_CERT_LOCATION}" ]; then
        echo "WARNING: Certificate file not found: ${HARBOR_NGINX_CERT_LOCATION}"
    fi
    if [ ! -f "${HARBOR_NGINX_KEY_LOCATION}" ]; then
        echo "WARNING: Private key file not found: ${HARBOR_NGINX_KEY_LOCATION}"
    fi
fi

# Ensure yq is available for YAML processing
if ! command -v yq &> /dev/null; then
    echo "Installing yq for YAML processing..."
    sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    sudo chmod +x /usr/local/bin/yq
fi

# Generate harbor.yml from template with current environment variables
if [ "${HARBOR_HTTPS_ENABLED:-true}" = "false" ]; then
    echo "HTTPS disabled: Removing HTTPS section from harbor.yml..."
    # Remove the HTTPS section entirely when HTTPS is disabled
    yq 'del(.https)' harbor.yml.tmpl | envsubst > harbor.yml
else
    echo "HTTPS enabled: Including HTTPS configuration in harbor.yml..."
    cat harbor.yml.tmpl | envsubst > harbor.yml
fi

if [[ "${ENV_NAME,,}" == "replica" ]]; then
  echo "WARN: INSTALLING WITHOUT TRIVY SINCE THIS IS A REPLICA"
  sudo ./install.sh

else
  echo "WARN: INSTALLING WITH TRIVY SINCE THIS IS NOT A REPLICA"
  sudo ./install.sh --with-trivy
fi

cd ../opentofu-setup

TOFU_VERSION="1.10.5"
echo "Downloading OpenTofu v${TOFU_VERSION} to the current directory..."
curl -s -Lo tofu.zip "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_linux_amd64.zip"
unzip -p tofu.zip tofu > tofu
chmod +x tofu
rm tofu.zip || true
sleep 10s

echo "OpenTofu configuration:"
echo "  Harbor URL: ${HARBOR_URL:-Not set}"
echo "  Harbor Username: ${HARBOR_USERNAME:-Not set}"
echo "  Registry Mode: ${TF_VAR_harbor_registry_mode:-CORE}"
echo "  Core Hostname: ${TF_VAR_harbor_core_hostname:-N/A}"

./tofu --version
./tofu init
./tofu plan
./tofu apply -auto-approve
docker ps -a

cd ..



# Convert NGINX_MODE to lowercase for consistent comparison
NGINX_MODE=${NGINX_MODE,,}
echo "Running NGINX in $NGINX_MODE mode"

# Base command arguments that are always present
DOCKER_ARGS=(
  -d
  --name nginx-redirect
  --network harbor_harbor
  -p 80:80
  -p 443:443
  -v "$NGINX_CERT_LOCATION:/etc/nginx/ssl/cert.pem:ro"
  -v "$NGINX_KEY_LOCATION:/etc/nginx/ssl/key.pem:ro"
  -v "$(pwd)/nginx-configs/default.conf.template:/etc/nginx/templates/default.conf.template:ro"
)

# Conditionally add the REPLICA_CONFIG environment variable
if [ "$NGINX_MODE" = "replica" ]; then
  echo "Replica mode detected, enabling REPLICA_CONFIG."
  # Add the -e flag and the file content as two separate elements to the array
  DOCKER_ARGS+=(-e "REPLICA_CONFIG=$(cat $(pwd)/nginx-configs/replica.conf)")
fi

# Execute the final docker run command
# The "${DOCKER_ARGS[@]}" syntax expands the array correctly
docker run "${DOCKER_ARGS[@]}" nginx:mainline-alpine@sha256:42a516af16b852e33b7682d5ef8acbd5d13fe08fecadc7ed98605ba5e3b26ab8


docker run -d \
--name harbor-health-check \
-p 1337:1337 \
--add-host=host.docker.internal:host-gateway \
-v $(pwd)/health-check/health-check.py:/app/health-check.py:ro \
python:3-alpine@sha256:9ba6d8cbebf0fb6546ae71f2a1c14f6ffd2fdab83af7fa5669734ef30ad48844 sh -c 'cd /app && python health-check.py'

echo ""
echo "✅ Setup completed successfully for environment: $ENV_NAME"
