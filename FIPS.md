# Building FIPS 140-2 compliant images

This document briefly describes how to build `cert-manager` Docker images containing FIPS-compliant binaries. It's not a FIPS, FedRAMP nor SSL/TLS guide, you'll find lots of better documentation about those out there.

## Motivation

If you or your company are into FedRAMP certification like New Relic is, at some point you'll have to set up encryption in transit. That is, all data moving from one service to another across the network (even inside the same cluster and/or private network) needs to be encrypted to avoid attacks. `cert-manager` is a key component of many Kubernetes clusters, and as such it needs to be FIPS-compliant as well if our clusters are to be FedRAMP certified.

Currently the FIPS 140-2 standard is required to achieve FedRAMP certification. [Here's](https://stackarmor.com/understanding-fips-140-2-requirements-for-achieving-fedramp-compliance/) a good and short read about that.

Not all SSL/TLS libraries are valid to build FIPS-compliant software. In Go specifically the standard crypto library does not provide FIPS compliancy so we need to use alternatives.

## BoringSSL and BoringCrypto

[BoringSSL](https://boringssl.googlesource.com/boringssl/) is a fork of OpenSSL, created by Google, which provides FIPS compliancy.

There's a [Golang branch](https://github.com/golang/go/tree/dev.boringcrypto) in the official Golang repository which uses BoringSSL instead of the standard crypto library. Such branch is also maintained by Google. [This read](https://github.com/golang/go/tree/dev.boringcrypto/misc/boring) is particularly relevant (especially the `Building from Docker` and the `Caveats` sections).

All in all, there exists a Docker image that ships a Go distribution which uses FIPS-compliant crypto libraries. This is what we're going to use.

## What we did (what's this repository for)

1. Create a Docker image which will be used as builder.

	To build it use the provided [Dockerfile.fips](Dockerfile.fips) file. This container will be based on `goboring/golang` (so it will contain BoringSSL libraries) and will also have [Bazel](https://bazel.build/) installed, needed to build `cert-manager` images. In this example we'll tag such container as `fips-build:release-1`:

	`$ docker build -t fips-build:release-1 -f Dockerfile.fips .`

1. Launch the build process inside the build container.

	We'll be using the underlying Docker daemon, so we can run Docker in Docker. To do so launch the container bind mounting the host's Docker socket: `-v /var/run/docker.sock:/var/run/docker.sock`

	Also mount your clone of this repo inside the container and use the mount target as working directory: `-v ${PWD}:/cert-manager -w /cert-manager`.

	Finally, pass in the `DOCKER_REGISTRY` and `APP_VERSION` values as environment variables to customise your images names and tags: `-e DOCKER_REGISTRY=newrelic -e APP_VERSION=1.1-nr1`.

	The final command might look like the following:

	```sh
	$ docker run \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v ${PWD}:/cert-manager \
	-w /cert-manager \
	-e DOCKER_REGISTRY=newrelic \
	-e APP_VERSION=1.1-nr1 \
	fips-build:release-1 \
	make fips_images
	```

1. Profit.

	You should now have your FIPS-compliant `cert-manager` images built and ready to be used.

## Under the hood

We've created a bunch of new `make` targets inside the `Makefile`, which in turn use some simple Bash scripts, all living in `hack/`:

- `fips-params.sh` will change some build settings so `CGO` can be used. This is needed so the binaries are compiled using the BoringSSL libraries. You can use `goversion` (bundled in the builder Docker image) to check that.
- `fips-tags.sh` will retag the built images, removing an `-amd64` suffix.
- `fips-push.sh` will just push all built images up to the specified Docker registry.

