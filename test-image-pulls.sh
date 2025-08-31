#!/usr/bin/env bash
set -e

# Define an array of images to test
images=(
    "localhost:80/proxy-docker-io/alpine:latest"
    "localhost:80/proxy-docker-io/nginx/nginx-ingress:latest"
    "localhost:80/proxy-quay-io/argoproj/argocd:latest"
    # "localhost:80/istio-release/base:1.25-2025-08-28T19-03-14"
    "localhost:80/proxy-ghcr-io/argoproj/argocd:latest"
    "localhost:80/proxy-public-ecr-aws/nginx/nginx:latest"
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