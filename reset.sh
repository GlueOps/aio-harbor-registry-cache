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
mv cert.pem ../$backup_folder/cert.pem
mv key.pem ../$backup_folder/key.pem
mv configs/*.env ../$backup_folder/configs
sudo git clean -xdf
git reset --hard
mv ../$backup_folder/cert.pem .
mv ../$backup_folder/key.pem
mv ../$backup_folder/configs/*.env configs/