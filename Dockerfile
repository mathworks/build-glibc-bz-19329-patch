# Copyright 2021 The MathWorks, Inc.
ARG BUILD_ROOT=/opt/glibc/src/glibc/

# Default to building for glibc 2.31 in ubuntu:20.04 but by specifying
# --build-arg RELEASE=18.04 in the docker build phase this will build for 
# glibc 2.27
ARG ARCH=
ARG DIST_BASE=ubuntu
ARG DIST_TAG=20.04
FROM ${ARCH}${DIST_BASE}:${DIST_TAG} AS build-stage

ARG DIST_BASE
ARG DIST_TAG
ARG OVERRIDE_DIST_RELEASE=false

ENV DEBIAN_FRONTEND="noninteractive" \
    TZ="Etc/UTC" 

RUN apt-get update && apt-get install --no-install-recommends -y \
    quilt \ 
    nano \ 
    devscripts

ARG PKG_EXT
ARG BUILD_ROOT
WORKDIR ${BUILD_ROOT}

# Build glibc in 3 distinct stages
#  1. Get the build envionment and source code
#  2. Patch the source code
#  3. Build the source code

COPY scripts/setup-glibc-build-env-vars.sh ${BUILD_ROOT}/
COPY scripts/get-glibc-src.sh ${BUILD_ROOT}/
RUN ./get-glibc-src.sh

COPY patches/ ${BUILD_ROOT}/patches/ 
COPY scripts/patch-glibc-src.sh ${BUILD_ROOT}/
RUN ./patch-glibc-src.sh

COPY scripts/build-glibc-src.sh ${BUILD_ROOT}/
RUN ./build-glibc-src.sh

RUN tar -czf all-packages.tar.gz *.deb

FROM scratch AS release-stage
ARG BUILD_ROOT
COPY --from=build-stage ${BUILD_ROOT}/*.deb /build/
COPY --from=build-stage ${BUILD_ROOT}/all-packages.tar.gz /build/
