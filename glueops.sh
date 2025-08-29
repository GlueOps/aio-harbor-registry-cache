#!/usr/bin/env bash
cd harbor
docker compose down
docker system prune -a -f
git clean -xdf
source .env
cat harbor.yml.tmpl | envsubst > harbor.yml
sudo ./install.sh
cd ../opentofu-setup
tofu init
tofu plan
tofu apply