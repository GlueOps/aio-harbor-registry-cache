#!/usr/bin/env bash
set -e

#stop all containers except for codespace (this helps for local dev cycles)
ID_TO_KEEP=$(docker ps -a -q --filter name="^/codespace$")
IDS_TO_STOP=$(docker ps -a -q | grep -v "${ID_TO_KEEP}")
if [ -n "$IDS_TO_STOP" ]; then
  docker stop $IDS_TO_STOP
else
  echo "No other containers to stop."
fi

docker system prune -a -f
git clean -xdf
git reset --hard