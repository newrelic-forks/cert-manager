# Building FIPS 140-2 compliant images

This document briefly describes how to build `cert-manager` Docker images containing FIPS-compliant binaries. It's not a FIPS, FedRAMP nor SSL/TLS guide, you'll find lots of better documentation about those out there.

## Motivation

If you or your company are into FedRAMP certification like New Relic is, at some point you'll have to set up encryption in transit. That is, all data moving from one service to another across the network (even inside the same cluster and/or private network) needs to be encrypted to avoid attacks. `cert-manager` is a key component of many Kubernetes clusters, and as such it needs to be FIPS-compliant as well if our clusters are to be FedRAMP certified.

Currently, the FIPS 140-2 standard is required to achieve FedRAMP certification. [Here's](https://stackarmor.com/understanding-fips-140-2-requirements-for-achieving-fedramp-compliance/) a good and short read about that.

Not all SSL/TLS libraries are valid to build FIPS-compliant software. In Go specifically the standard crypto library does not provide FIPS compliance, so we need to use alternatives.

## BoringCrypto

Google publishes a fork of Go that uses BoringCrypto (the core of BoringSSL), which replaces the standard crypto primitives with FIPS validated variants.
The code is published in the main Go repository behind the setting GOEXPERIMENT=boringcrypto.

Caveats apply:
> To be clear, we are not making any statements or representations about the suitability of this code in relation to the FIPS 140 standard. 
> Interested users will have to evaluate for themselves whether the code is useful for their own purposes.

More information:
* https://go.dev/src/crypto/internal/boring/README
* https://boringssl.googlesource.com/boringssl/+/master/crypto/fipsmodule/FIPS.md

## How To Build

1. Create a Docker image which will be used as builder.

   To build it use the provided [Dockerfile.fips](Dockerfile.fips) file. This container has Golang and Podman installed to build images. In this example we'll tag such container as `fips-build:release-1`:

   `$ docker build -t fips-build:release-1 -f Dockerfile.fips .`

1. Launch the build process inside the build container.

   Mount your clone of this repo inside the container and use the mount target as working directory: `-v ${PWD}:/cert-manager -w /cert-manager`.

   Finally, pass in the `DOCKER_REGISTRY` and `APP_VERSION` values as environment variables to customise your images names and tags: `-e DOCKER_REGISTRY=newrelic -e APP_VERSION=1.12.10-nr1`.

   The final command might look like the following:

   ```sh
   $ docker run \
   --platform=linux/amd64 \
   -it \
   -v ${PWD}:/cert-manager \
   -w /cert-manager \
   -e DOCKER_REGISTRY=newrelic \
   -e APP_VERSION=v1.12.10-nr1 \
   fips-build:release-1 \
   /cert-manager/build.sh
   ```

1. Profit.

   You should now have your FIPS-compliant `cert-manager` images built and ready to be used.

## Notes
Significant modifications were made to the Makefile to get this to build for v1.12.10-nr1. 
It is likely that the structure of the Makefile will change, and similar changes will need to take place with the newer release (breaking this script).

Here is the gist of the changes made:

* The base image needs to use a dynamic image
  * make/containers.mk:16 -- `BASE_IMAGE_TYPE:=DYNAMIC`
* The dynamic image needed to be a debian version that contained a new enough libc library
  * make/base_images.mk:8 -- `DYNAMIC_BASE_IMAGE_amd64 := gcr.io/distroless/base-debian12`
* Only needed to build amd64 image
  * make/containers.mk:55 -- `cert-manager-controller-linux: $(BINDIR)/containers/cert-manager-controller-linux-amd64.tar.gz`
  * make/containers.mk:68 -- `cert-manager-webhook-linux: $(BINDIR)/containers/cert-manager-webhook-linux-amd64.tar.gz`
  * make/containers.mk:68 -- `cert-manager-cainjector-linux: $(BINDIR)/containers/cert-manager-cainjector-linux-amd64.tar.gz`
  * make/containers.mk:94 -- `cert-manager-acmesolver-linux: $(BINDIR)/containers/cert-manager-acmesolver-linux-amd64.tar.gz`
  * make/containers.mk:107 -- `cert-manager-ctl-linux: $(BINDIR)/containers/cert-manager-ctl-linux-amd64.tar.gz`
* Changed how tags were generated
  * make/containers.mk:58 -- `@$(eval TAG := $(REGISTRY)/cert-manager-controller:$(RELEASE_TAG))`
  * make/containers.mk:71 -- `@$(eval TAG := $(REGISTRY)/cert-manager-webhook:$(RELEASE_TAG))`
  * make/containers.mk:84 -- `@$(eval TAG := cert-manager-cainjector:$(RELEASE_TAG))`
  * make/containers.mk:97 -- `@$(eval TAG := cert-manager-acmesolver:$(RELEASE_TAG))`
  * make/containers.mk:110 -- `@$(eval TAG := cert-manager-ctl:$(RELEASE_TAG))`


