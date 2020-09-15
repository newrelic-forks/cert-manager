#!/usr/bin/env bash

# +skip_license_check

set -o errexit

# Use the host's Go installation
# This expects the compilation to happen in a goboring/golang container
sed -i 's/go_version\ =\ ".*"/go_version\ =\ "host"/' WORKSPACE

# Change 'pure' parameter for all Go binaries
# This enables CGO
for CMD in $(ls cmd/); do
    sed -i 's/pure\ =\ "on"/pure\ =\ "off"/' cmd/${CMD}/BUILD.bazel
done

# Change compile image to distroless/base
# We're using CGO, a static image won't work
sed -i 's/repository\ =\ "distroless\/static"/repository\ =\ "distroless\/base"/' build/images.bzl
sed -i '/digest\ =\ ".*$/d' build/images.bzl
