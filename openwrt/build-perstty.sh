#!/bin/bash -e

PKG_NAME=persistent-tty

if [ -f .config ]; then
    # rebuild
    make package/${PKG_NAME}/clean
else
    # configure SDK first
    cat feeds.conf.default feeds-perstty.conf >> feeds.conf
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    ./scripts/feeds install ${PKG_NAME}

    cp diffconfig .config
    make defconfig
fi

make package/${PKG_NAME}/compile
make package/index

IPK=$(ls bin/packages/*/perstty/*.ipk)
echo "Package: $IPK"
