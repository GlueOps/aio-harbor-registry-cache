#!/usr/bin/env bash
set -e


echo "THIS WILL DELETE/RESET ANY GIT CHANGES!!"
sleep 5;

#stop all containers except for codespace (this helps for local dev cycles)
cd harbor
sudo docker-compose down || true
sudo docker stop nginx-simple-redirect || true
cd ..
docker system prune -a -f
sudo git clean -xdf
git reset --hard