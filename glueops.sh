#!/usr/bin/env bash
cd harbor
source .env
cat harbor.yml.tmpl | envsubst > harbor.yml
./install.sh