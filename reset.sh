#!/usr/bin/env bash
set -e


echo "THIS WILL DELETE/RESET ANY GIT CHANGES!!"
sleep 5;

#stop all containers except for codespace (this helps for local dev cycles)
cd harbor
sudo docker compose down || true
sudo docker stop nginx-redirect || true
sudo docker stop  harbor-health-check || true
cd ..
docker system prune -a -f
backup_folder=backup-$(date +%s)
mkdir -p ../$backup_folder/configs
cp cert.pem ../$backup_folder/cert.pem
cp key.pem ../$backup_folder/key.pem
cp configs/*.env ../$backup_folder/configs
sudo git clean -xdf
git reset --hard
cp ../$backup_folder/cert.pem .
cp ../$backup_folder/key.pem .
cp ../$backup_folder/config/*.env config/