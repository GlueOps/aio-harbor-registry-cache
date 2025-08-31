#!/usr/bin/env bash
set -e


echo "THIS WILL DELETE/RESET ANY GIT CHANGES!!"
sleep 5;

#stop all containers except for codespace (this helps for local dev cycles)
cd harbor
docker-compose down
cd ..
docker system prune -a -f
git clean -xdf
git reset --hard