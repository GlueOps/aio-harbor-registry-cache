#!/usr/bin/env bash
set -e

# Define an array of images to test
images=(
    "localhost:8080/proxy-docker-io/alpine:latest"
    "localhost:8080/proxy-docker-io/nginx/nginx-ingress:latest"
    "localhost:8080/proxy-quay-io/argoproj/argocd:latest"
    "localhost:8080/proxy-ghcr-io/argoproj/argocd:latest"
    "localhost:8080/proxy-public-ecr-aws/nginx/nginx:latest"
    "localhost:8080/proxy-mcr-microsoft-com/vscode/devcontainers/base:1-ubuntu-22"

)

echo "Testing registry proxy functionality..."
echo "-------------------------------------"

# Loop through the array to pull and then remove each image
for image in "${images[@]}"; do
    echo "⬇️  Pulling image: $image"
    docker pull "$image"
    
    echo "🗑️  Removing image: $image"
    docker image rm "$image"
    echo "-------------------------------------"
done

echo ""
echo "✅ Test completed successfully."
