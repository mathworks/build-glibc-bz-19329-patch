#!/bin/bash
# Copyright 2021 The MathWorks, Inc.

specfile=rpmbuild/SPECS/glibc.spec

last_patchnum=$(egrep '^Patch[0-9]+' $specfile | tail -1 | sed 's/^Patch\([0-9]\+\):.*/\1/')

sed -i "/^Patch${last_patchnum}:/a Patch$((last_patchnum+1)): glibc-bz19329-1-of-2.el8.patch" $specfile
last_patchnum=$((last_patchnum+1))
sed -i "/^Patch${last_patchnum}:/a Patch$((last_patchnum+1)): glibc-bz19329-2-of-2.el8.patch" $specfile
last_patchnum=$((last_patchnum+1))
sed -i "/^Patch${last_patchnum}:/a Patch$((last_patchnum+1)): glibc-bz19329-fixup.el8.patch" $specfile

sed -i 's/^\(%define glibcrelease [0-9]\+\)/\1.custom/' $specfile
