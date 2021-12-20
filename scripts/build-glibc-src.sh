#!/bin/bash
# Copyright 2021 The MathWorks, Inc.

source setup-glibc-build-env-vars.sh

pushd glibc-${VER}/

DEBIAN_FRONTEND="noninteractive" TZ="Etc/UTC" apt-get build-dep libc6 -y
env DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc -j$(nproc)