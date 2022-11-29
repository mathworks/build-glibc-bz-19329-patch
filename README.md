# Build `glibc` Patchs
## Summary
This repository provides a method for working around various issues seen in older linux distributions glibc libraries. The glibc libraries are so core to the behaviour of a system that they rarely get updated in older distributions, so we provide ways to patch those libraries. 

## Issues Currently Patched
* [BZ-19329](BZ-19329.md) ([bugzilla report](https://sourceware.org/bugzilla/show_bug.cgi?id=19329))  is a significant sporadic issue in all glibc versions up to 2.34. 
* [BZ-17645](BZ-17645.md) ([bugzilla report](https://sourceware.org/bugzilla/show_bug.cgi?id=17645)) is a significant performance issue on all glibc versions up to 2.35. 


### **Caution**
Note that **all** processes on your machine share glibc libraries so these patches will apply to the system as a whole and not just to MathWorks products. Most applications and programs on your computer are likely to use glibc. Care should be taken to ensure you apply the correct version of the patch to your system based on the current version of glibc. Applying the wrong version could make your whole system unusable. Try installing the patch inside a disposable docker container first to test your install procedure – you can find instructions below.

You can find the major version of glibc you are running using, for example:

```
$ ldd --version ldd

ldd (Ubuntu GLIBC 2.31-0ubuntu9.2) 2.31
Copyright (C) 2020 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
Written by Roland McGrath and Ulrich Drepper.
```

More specificity on version can be found using:
```
$ dpkg-query --show libc6:amd64
libc6:amd64     2.31-0ubuntu9.2
```

## Build procedure 
To build a specific version of glibc on your own machine you will need a version of `docker` that supports `BUILDKIT` (this feature was added in version 18.09). This repository holds patches for all glibc versions on debian derived systems from 2.24 to 2.33 inclusive, as well as a version for RHEL 8 with glibc 2.28. Running the build process takes between 10 and 60 mins based on the compute ability of your system.

### Pre-built artefacts
This repository runs a number of github actions to build artefacts for specific Debian, Ubuntu and RHEL versions and it is likely that these are all that is needed to patch your system. You can download the matching  packages for your system from the release area.

### Building
1. Clone this repository locally and change folder into the repository
```
    git clone https://github.com/mathworks/build-glibc-bz-19329-patch.git
    cd build-glibc-bz19329-patch
```
2. Build (using `docker build`) for the distribution and specific release you want to patch. Select the distribution and specific distribution version by setting the build argument `DIST_BASE` and `DIST_TAG`. `DIST_BASE:DIST_TAG` must be one of 

    | | | 
    | - | - |
    | `debian:9` | `debian:stretch` |
    | `debian:10`| `debian:buster` |
    | `debian:11`| `debian:bullseye` | 
    | `ubuntu:18.04` | `ubuntu:bionic` |
    | `ubuntu:20.04` | `ubuntu:focal` |
    | `ubuntu:21.04` | `ubuntu:hirsute` |
    | `almalinux:8.4` | |
    | `almalinux:8.5` | |

*Note*: You should only patch RHEL 8.4 or 8.5 if you cannot get `glibc-2.28-189.1.el8` onto the machine via the normal upgrade procedures.

Here is an example build command (for `debian:9`):
```
DOCKER_BUILDKIT=1 docker build --build-arg DIST_BASE=debian --build-arg DIST_TAG=9 --output type=local,dest=. .
```

The build command will use a local container image of the specific distribution requested, or pull one if none exists. To ensure you are building the most up-to-date versions of the libraries you should `docker pull` the specific `DIST_BASE:DIST_TAG` distribution before building. The build progresses and finally will copy the new debian package to a local folder called `./build/`. In that folder will be a libc6 debian package that can be installed on the appropriate distribution. For example having built for `debian:9`, `debian:10`, `debian:11`, and `ubuntu:20.04` the folder contains:

```
$ ls -x build/
libc6_2.24-11+deb9u4.custom_amd64.deb
libc6_2.27-3ubuntu1.4.custom_amd64.deb
libc6_2.28-10.custom_amd64.deb
libc6_2.31-13+deb11u2.custom_amd64.deb
```

When building for Almalinux you must use the `Dockerfile.rhel` rather than the debian `Dockerfile` so the build command is 
```
DOCKER_BUILDKIT=1 docker build --build-arg DIST_TAG=8.5 -f Dockerfile.rhel --output type=local,dest=. .
```

If you have access to a RHEL subscription you should be able to adapt the `Dockerfile.rhel` trivially to include the correct repos to support building the sources directly in a `ubi8` container.

### Overriding package version string
The package version extension defaults to `.DIST_BASE.DIST_TAG.custom`, where
`${DIST_TAG}` defaults to the `VERSION_CODENAME` found in `/etc/os-release`.  This version
can be overridden by setting the build argument `PKG_EXT`.

E.g., on Debian 11, the default packages will be named like
`libc6_2.31-13+deb11u2.debian.bullseye.custom_amd64.deb`.  If built with
`--build-arg PKG_EXT=.test`, the package would instead be named
`libc6_2.31-13+deb11u2.test_amd64.deb`.

## Installing the built packages
*Please note the caution above - take care not to install the wrong package version compared to the rest of your system. Consider trying the install in a disposable docker container first.*

Installing a specific debian package on a system is as simple as executing  
```
dpkg -i libc6_2.24-11+deb9u4.custom_amd64.deb
```
For your system replace the debian package with the correct version that matches the glibc you already have (see for example the output from `dpkg-query --show libc6:amd64`)

Installing the rpms on a UBI / Almalinux system requires you to install several of the packages at once, for example
```
dnf install -y  glibc-2.28-164.custom.el8.x86_64.rpm  \
                glibc-common-2.28-164.custom.el8.x86_64.rpm \
                glibc-minimal-langpack-2.28-164.custom.el8.x86_64.rpm
```

### Installing in a Docker container
When building a docker container with a specific patch, assuming the patch is in the top level docker context folder you would have a `Dockerfile` like
``` docker
FROM debian:9

COPY libc6_2.24-11+deb9u4.custom_amd64.deb /tmp/
RUN dpkg -i /tmp/libc6_2.24-11+deb9u4.custom_amd64.deb
```
