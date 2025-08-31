#!/usr/bin/env bash
set -e


docker stop $(docker ps -q)
docker system prune -a -f
git clean -xdf
git reset --hard