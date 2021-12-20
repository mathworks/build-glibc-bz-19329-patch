#!/bin/bash
# Copyright 2021 The MathWorks, Inc.

source setup-glibc-build-env-vars.sh


sed -i "/^deb\s.* ${DIST} main/{p;s/^deb\s/deb-src /}" /etc/apt/sources.list
sed -i "/^deb\s.* ${DIST}-updates main/{p;s/^deb\s/deb-src /}" /etc/apt/sources.list

apt-get update -y

apt-get source libc6

apt-get build-dep libc6 -y

