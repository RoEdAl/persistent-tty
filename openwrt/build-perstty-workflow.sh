#!/bin/bash -e

PKG_NAME=persistent-tty


if [ -f .config ]; then
    # rebuild
    echo '::group::make pkg clean'
    make package/${PKG_NAME}/clean
    echo '::endgroup::'
else
    echo '::group::Configure OpenWRT SDK'
    # configure SDK first
    cat feeds.conf.default feeds-perstty.conf >> feeds.conf
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    ./scripts/feeds install ${PKG_NAME}
    echo '::endgroup::'

    echo '::group::make defconfig'
    cp diffconfig .config
    make defconfig
    echo '::endgroup::'
fi

echo '::group::make pkg compile'
make package/${PKG_NAME}/compile
echo '::endgroup::'

echo '::group::make pkgs index'
make package/index
echo '::endgroup::'

IPK=$(ls bin/packages/*/perstty/*.ipk)
if [ -z "${IPK}" ]; then
   echo '::error::Cannot find IPK package'
   exit 1
fi

echo "::notice::Package: $IPK"
echo "Package: **$IPK**" >> $GITHUB_STEP_SUMMARY
