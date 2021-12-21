# Copyright 2021 The MathWorks, Inc.

DIST=$(grep -Po "(?<=VERSION_CODENAME=).*" /etc/os-release)

if [ ${OVERRIDE_DIST_RELEASE} = "true" ] ; then
    DIST=${DIST_RELEASE}
fi

PKGVER=$(dpkg-query --showformat='${Version}' --show libc6).${PKG_EXT-${DIST_BASE}.${DIST}.custom}
VER=$(echo ${PKGVER} | grep -Po "[0-9/.]+(?=-)")
