#!/usr/bin/env bash
set -e

cd harbor
docker compose down
docker system prune -a -f
sudo git clean -xdf
echo "create certs locally for testing"

openssl req \
    -x509 \
    -nodes \
    -newkey rsa:2048 \
    -keyout "key.pem" \
    -out "cert.pem" \
    -days 3650 \
    -subj "/CN=localhost" \
    -addext "subjectAltName = DNS:localhost,IP:127.0.0.1"

echo "Success! Created key.pem and cert.pem for localhost."

source .env
cat harbor.yml.tmpl | envsubst > harbor.yml
sudo ./install.sh
cd ../opentofu-setup
TOFU_VERSION="1.10.5"
echo "Downloading OpenTofu v${TOFU_VERSION} to the current directory..."
curl -s -Lo tofu.zip "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_linux_amd64.zip"
unzip -p tofu.zip tofu > tofu
chmod +x tofu
sleep 10s
source .env
./tofu --version
./tofu init
rm tofu.zip
./tofu plan
./tofu apply -auto-approve
docker ps -a

docker pull localhost:80/proxy-docker-io/alpine:latest
docker pull localhost:80/proxy-docker-io/nginx/nginx-ingress:latest
docker pull localhost:80/proxy-quay-io/argoproj/argocd:latest
#docker pull localhost:80/istio-release/base:1.25-2025-08-28T19-03-14
docker pull localhost:80/proxy-ghcr-io/argoproj/argocd:latest
docker pull localhost:80/proxy-public-ecr-aws/nginx/nginx:latest
