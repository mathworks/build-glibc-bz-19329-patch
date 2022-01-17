# Build `glibc` BZ-19329 Patch
## Summary
This repository provides a method for working around the sporadic issue seen on older linux distributions: MathWorks&reg; products can trigger an [assert failure at concurrent pthread_create and dlopen (BZ-19329)](https://sourceware.org/bugzilla/show_bug.cgi?id=19329) in the [GNU C Libraries (glibc)](https://www.gnu.org/software/libc/).

If you are running an ubuntu-based system and can upgrade to **version 21.10 (Impish Indri)** this is the safest and easiest way to alleviate the issue, since that version contains glibc v2.34 in which the underlying issue is completely fixed.

If instead you want to work around this issue, you can use this repository. It provides a build procedure (in an isolated Docker&reg; container) to produce patched versions of the glibc libraries for recent Almalinux, Ubuntu&reg; and Debian&reg; releases. These patched versions [incorporate an initial fix](https://patchwork.ozlabs.org/project/glibc/patch/568D5E11.3010301@arm.com/) proposed on the [libc-alpha mailing list](https://sourceware.org/mailman/listinfo/libc-alpha) that mitigate the issue. In the release area of this repository you can find the debian package build artefacts produced by running the build on Ubuntu 18.04 & 20.04 as well as Debian 9, 10 & 11. You can install these artefacts on an appropriate debian-based machine, virtual machine or docker container, by using `dpkg -i`. For Almalinux you cand find the appropriate `rpm's` which should also work on UBI and CentOS containers.

## Bug Description 
The [assert failure at concurrent pthread_create and dlopen](https://sourceware.org/bugzilla/show_bug.cgi?id=19329) glibc bug was first reported in December 2015 and can affect any process on Linux that creates a thread at the same time as opening a dynamic shared object library. Initially the issue was only observable with reasonable frequency on very large scale machine systems such as high performance computing clusters or cloud scale deployment platforms and so did not receive significant attention. However, early on there were [proposed patches](https://sourceware.org/bugzilla/show_bug.cgi?id=19329) to the library. Large scale systems applied those patches in-house and saw significant benefit. More recently a [proposed complete fix for this](https://sourceware.org/pipermail/libc-alpha/2021-February/122626.html) and a set of related issues has been reviewed by the glibc team and accepted into version 2.34 of glibc (released in August 2021). The 2.34 version of glibc is available in [RHEL 9 beta](https://developers.redhat.com/articles/2021/11/03/red-hat-enterprise-linux-9-beta-here) and [Ubuntu 21.10 (Impish Indri)](https://launchpad.net/ubuntu/+source/glibc). However, there are no plans to backport the fix into previous glibc versions and it is expected that previous versions will be in production use for a significant number of years (e.g. the current end-of-life date for Ubuntu:20.04 is April 2030). 

More recently MathWorks products have made extensive use of a C++ micro-services architecture. This architecture leads to a more dynamic system in which library modules are loaded at the point of use. As a result, the MATLAB&reg; process is more likely to load a library at the same time as creating a thread, and so is more likely to encounter this glibc bug. When this [issue is encountered](https://www.mathworks.com/matlabcentral/answers/1454674-why-does-matlab-crash-on-linux-with-inconsistency-detected-by-ld-so-elf-dl-tls-c-597-_dl_allo) the console that opened MATLAB shows a message similar to the following:

```
Inconsistency detected by ld.so: ../elf/dl-tls.c: 597: _dl_allocate_tls_init: Assertion 'listp != NULL' failed!
```
or
```
Inconsistency detected by ld.so: dl-tls.c: 493: _dl_allocate_tls_init: Assertion `listp->slotinfo[cnt].gen <= GL(dl_tls_generation)' failed!
```
There might also be a stack trace file called `matlab_crash_dump.${PID}` in the users home folder or the current working folder. This usually inidicates that a segmentation violation has been detected and the stack trace starts with something similar to the following:

```
Stack Trace (from fault):
[  0] 0x00002b661142d5a0    /lib64/ld-linux-x86-64.so.2+00075168 _dl_allocate_tls_init+00000080
[  1] 0x00002b66120c187c    /usr/lib64/libpthread.so.0+00034940 pthread_create+00001884
```

If you see these or similar signatures at a sufficient frequency on a system, you might want to consider patching glibc on your machines or containers. 

### **Caution**
Note that **all** processes on your machine share glibc so this patch will apply to the system as a whole and not just to MathWorks products. Most applications and programs on your computer are likely to use glibc. Care should be taken to ensure you apply the correct version of the patch to your system based on the current version of glibc. Applying the wrong version could make your whole system unusable. Try installing the patch inside a disposable docker container first to test your install procedure – you can find instructions below.

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
This repository runs a number of github actions to build artefacts for specific Debian and Ubuntu versions and it is likely that these are all that is needed to patch your system. You can download the matching debian package for your system from the release area.

### Building
1. Clone this repository locally and change folder into the repository
```
    git clone https://build-glibc-bz19329-patch.github.com
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

## Patch sources
These patches all derive from an [original patch](https://sourceware.org/legacy-ml/libc-alpha/2016-01/msg00480.html) put together by Szabolcs Nagy in January 2016. The 2.24 to 2.28 patches in this repo are  derived from this original e-mail and can be downloaded directly from the archive of the `libc-alpha@sourceware.org` mailing list where they were proposed:

* https://sourceware.org/legacy-ml/libc-alpha/2016-11/msg01092.html
* https://sourceware.org/legacy-ml/libc-alpha/2016-11/msg01093.html

These 2 patches are directly linked in [the original bug report](https://sourceware.org/bugzilla/show_bug.cgi?id=19329) in comment 7 by Pádraig Brady. In addition, the bug report also has a reference to the original Szabolcs Nagy patch in comment 4 (dated January 2016). The 2 messages above refer back to that original patch via a [message describing the overall problem in more detail](https://sourceware.org/legacy-ml/libc-alpha/2016-11/msg01026.html).

In addition, in [Sept 2017 Pádraig Brady](https://sourceware.org/bugzilla/show_bug.cgi?id=19329) pointed out that there was an off-by-one error in the original patch that needs to be included
``` diff
diff --git a/elf/dl-tls.c b/elf/dl-tls.c
index 073321c..2c9ad2a 100644
--- a/elf/dl-tls.c
+++ b/elf/dl-tls.c
@@ -571,7 +571,7 @@ _dl_allocate_tls_init (void *result)
        }

       total += cnt;
-      if (total >= dtv_slots)
+      if (total > dtv_slots)
        break;

       /* Synchronize with dl_add_to_slotinfo.  */
```
This is source for the final `unsubmitted-bz19329-fixup.v2.27.patch`

In glibc v2.31 the original source code changed significantly and the patches needed to be slightly adapted so as to match the new codebase. These adapted patches are included here in the `patches/2.31` folder and soft-linked from 2.32 and 2.33.

## Acknowledgement and thanks
Many thanks to the broader glibc team and particularly Szabolcs Nagy for providing the original patches and for fixing these issues in glibc v2.34.
