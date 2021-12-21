# Copyright 2021 The MathWorks, Inc.

# Default to building for glibc 2.31 in ubuntu:20.04 but by specifying
# --build-arg RELEASE:18.04 in the docker build phase this will build for 
# glibc 2.27
ARG ARCH=
ARG DIST_BASE=ubuntu
ARG DIST_TAG=20.04
FROM ${ARCH}${DIST_BASE}:${DIST_TAG} AS build-stage


ARG DIST_BASE
ARG DIST_TAG
ARG OVERRIDE_DIST_RELEASE=false

ENV DEBIAN_FRONTEND="noninteractive" \
    TZ="Etc/UTC" \
    DIST_BASE=${DIST_BASE} \
    DIST_RELEASE=${DIST_TAG} \
    OVERRIDE_DIST_RELEASE=${OVERRIDE_DIST_RELEASE}

RUN apt-get update && apt-get install --no-install-recommends -y \
    quilt \ 
    nano \ 
    devscripts

ARG BUILD_ROOT=/opt/glibc/src/glibc/
ARG PKG_EXT
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

RUN mkdir /tmp/build
RUN cp ${BUILD_ROOT}/*.deb /tmp/build/

FROM scratch AS release-stage
COPY --from=build-stage /tmp/build/*.deb /build/
