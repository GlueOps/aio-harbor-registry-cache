#!/usr/bin/env bash
set -e


echo "THIS WILL KILL YOUR CODESPACE, IT WILL ALSO DELETE/RESET ANY GIT CHANGES!!"
sleep 10;

#stop all containers except for codespace (this helps for local dev cycles)
docker stop $(docker ps -q)
docker system prune -a -f
git clean -xdf
git reset --hard