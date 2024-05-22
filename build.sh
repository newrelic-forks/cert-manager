#!/bin/bash

set -ox errexit

# Build images with BoringCrypto enabled
echo "Building cert-manager images..."
make CGO_ENABLED=1 GOEXPERIMENT=boringcrypto GOOS=linux CTR="podman --events-backend=file" REGISTRY="${DOCKER_REGISTRY}" RELEASE_TAG="${APP_VERSION}" all-containers

# Push images
pushd cmd
for COMPONENT in *; do
    if [[ $(podman images -q "${DOCKER_REGISTRY}/cert-manager-${COMPONENT}:${APP_VERSION}") != "" ]]; then
        podman push "${DOCKER_REGISTRY}/cert-manager-${COMPONENT}:${APP_VERSION}"
    fi
done
popd