#!/usr/bin/env bash
cd harbor
cat harbor.yml.tmpl | envsubst > harbor.yml
./install.sh