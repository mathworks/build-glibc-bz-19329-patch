#!/bin/bash
# Copyright 2021 The MathWorks, Inc.

source setup-glibc-build-env-vars.sh

cat << 'EOF' >> ~/.quiltrc
d=. ; while [ ! -d $d/debian -a `readlink -e $d` != / ]; do d=$d/..; done
if [ -d $d/debian ] && [ -z $QUILT_PATCHES ]; then
        # if in Debian packaging tree with unset $QUILT_PATCHES
        QUILT_PATCHES="debian/patches"
        QUILT_PATCH_OPTS="--reject-format=unified"
        QUILT_DIFF_OPTS="-p"
        QUILT_DIFF_ARGS="-p ab --no-timestamps --no-index --color=auto"
        QUILT_REFRESH_ARGS="-p ab --no-timestamps --no-index"
        QUILT_COLORS="diff_hdr=1;32:diff_add=1;34:diff_rem=1;31:diff_hunk=1;33:diff_ctx=35:diff_cctx=33"
        if ! [ -d $d/debian/patches ]; then mkdir $d/debian/patches; fi
fi
EOF

PATCH_FOLDER=$(pwd)/patches/${VER}

pushd glibc-${VER}/debian/patches
cp ${PATCH_FOLDER}/unsubmitted-bz19329-*.patch any/
echo any/unsubmitted-bz19329-* | tr ' ' '\n' >> series
 
quilt push
quilt refresh
quilt push
quilt refresh
quilt push
quilt refresh
 
quilt pop -a  
  
dch --newversion="${PKGVER}" "patching glibc"