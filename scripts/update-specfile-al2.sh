#!/bin/bash
# Copyright 2025 The MathWorks, Inc.

specfile=rpmbuild/SPECS/glibc.spec
patchfile=rpmbuild/SOURCES/glibc.patches

last_patchnum=$(egrep '^Patch[0-9]+' $patchfile | tail -1 | sed 's/^Patch\([0-9]\+\):.*/\1/')
buildid=$(egrep '%define _buildid\s+' $specfile | tail -1 | sed 's/^%define _buildid\s\+\.//')
new_buildid=$((buildid+1))

for p in `ls patches/`
do
    echo "push patch $p"
    sed -i "/^Patch${last_patchnum}:/a Patch$((last_patchnum+1)): ${p}" $patchfile
    last_patchnum=$((last_patchnum+1))
done

sed -i "/^Patch${last_patchnum}:/a %global _default_patch_fuzz 2" $patchfile
sed -i "s/^\(%define _buildid\s\+\)\.${buildid}/\1.${new_buildid}/" $specfile