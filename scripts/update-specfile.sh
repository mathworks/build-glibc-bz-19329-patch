#!/bin/bash
# Copyright 2021 The MathWorks, Inc.

specfile=rpmbuild/SPECS/glibc.spec

last_patchnum=$(egrep '^Patch[0-9]+' $specfile | tail -1 | sed 's/^Patch\([0-9]\+\):.*/\1/')

for p in `ls patches/`
do
    echo "push patch $p"
    sed -i "/^Patch${last_patchnum}:/a Patch$((last_patchnum+1)): ${p}" $specfile
    last_patchnum=$((last_patchnum+1))
done

sed -i "/^Patch${last_patchnum}:/a %global _default_patch_fuzz 2" $specfile
sed -i 's/^\(%define glibcrelease [0-9]\+\)/\1.custom/' $specfile
