#!/usr/bin/env bash
set -e

#stop all containers except for codespace (this helps for local dev cycles)
docker stop $(docker ps -a -q | grep -v $(docker ps -a -q --filter name="^/codespace$"))
docker system prune -a -f
git clean -xdf
git reset --hard