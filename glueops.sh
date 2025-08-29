#!/usr/bin/env bash
cd harbor
docker compose down
docker system prune -a -f
sudo git clean -xdf
source .env
cat harbor.yml.tmpl | envsubst > harbor.yml
sudo ./install.sh
cd ../opentofu-setup
tofu init
sleep 10;
docker ps -a
tofu plan
echo "apply things"
tofu plan
tofu apply -auto-approve
cd ..


docker pull localhost:80/proxy-docker-io/alpine:latest
docker pull localhost:80/proxy-docker-io/nginx/nginx-ingress:latest
docker pull localhost:80/proxy-quay-io/argoproj/argocd:latest
#docker pull localhost:80/istio-release/base:1.25-2025-08-28T19-03-14
docker pull localhost:80/proxy-ghcr-io/argoproj/argocd:latest
docker pull localhost:80/proxy-public-ecr-aws/nginx/nginx:latest
