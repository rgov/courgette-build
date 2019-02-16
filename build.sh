#!/bin/sh -e

# This is the second half of the process of building Courgette; the Dockerfile
# sets up the environment and configures the build. Now we need to actually
# perform the build and package the results.
#
# https://chromium.googlesource.com/chromium/src/+/master/docs/linux_build_instructions.md

cd /root/chromium/src
GITHASH=$(git rev-parse --short HEAD)

# Update the checkout and re-sync dependencies and hooks
git rebase-update
gclient sync

# Build Courgette
autoninja -C out/Default courgette

# Build the Debian package
mkdir -p /root/courgette/usr/bin /root/courgette/usr/lib
cp out/Default/courgette /root/courgette/usr/bin
cp $(ldd out/Default/courgette | grep '/root' | awk '{ print $3 }') \
    /root/courgette/usr/lib
sed -i "s/@GITHASH@/$GITHASH/g" \
    /root/courgette/DEBIAN/control
dpkg-deb --build /root/courgette
mv /root/courgette.deb /root/out/courgette-${GITHASH}.deb

# Install the Debian package and test it
dpkg -i /root/out/courgette-*.deb
courgette --help 2>&1 | grep -q 'genbsdiff'
