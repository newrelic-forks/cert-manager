#!/bin/bash

REGISTRY=${1}
TAG=${2}

# Remove arch from image names
echo "Removing '-amd64' suffix from image names..."
for COMPONENT in $(ls cmd/); do
    if [[ $(docker images -q ${REGISTRY}/cert-manager-${COMPONENT}-amd64:${TAG}) != "" ]]; then
        echo "Tagging ${REGISTRY}/cert-manager-${COMPONENT}-amd64:${TAG} as ${REGISTRY}/cert-manager-${COMPONENT}:${TAG}"
        docker tag ${REGISTRY}/cert-manager-${COMPONENT}-amd64:${TAG} ${REGISTRY}/cert-manager-${COMPONENT}:${TAG}
        docker rmi ${REGISTRY}/cert-manager-${COMPONENT}-amd64:${TAG}
    fi
done
