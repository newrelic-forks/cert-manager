#!/bin/bash

REGISTRY=${1}
TAG=${2}

# Push images
for COMPONENT in $(ls cmd/); do
    if [[ $(docker images -q ${REGISTRY}/cert-manager-${COMPONENT}:${TAG}) != "" ]]; then
        docker push ${REGISTRY}/cert-manager-${COMPONENT}:${TAG}
    fi
done
