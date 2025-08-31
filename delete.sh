#!/usr/bin/env bash
set -e


docker stop $(docker ps -q)
docker system prune -a
git clean -xdf
git reset --hard