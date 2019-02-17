#!/bin/bash -e

# This script builds the Courgette target from Chromium. It works on macOS and
# Linux. Please see the accompanying README.md file.
#
# https://www.chromium.org/developers/how-tos/get-the-code

function status {
  printf '\E[33m'
  echo "$@"
  printf '\E[0m'
}

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 workspace-dir [fetch-only|no-update]" >&2
  exit 1
fi

# Enter the workspace
mkdir -p "$1"
cd "$1"

# Install depot_tools
if [ ! -d depot_tools ]; then
  status "[*] Cloning depot_tools"
  git clone --depth 1 \
    https://chromium.googlesource.com/chromium/tools/depot_tools.git
elif [ "$2" != "no-update" ]; then
  status "[*] Updating depot_tools"
  pushd depot_tools
  git pull
  popd
fi

export PATH="$(pwd)/depot_tools:${PATH}"

# Is this our first build?
if [ ! -f .first-build-finished ]; then
  FIRST_BUILD=1
else
  FIRST_BUILD=0
fi

# Get the code
if [ ! -d chromium/src ]; then
  status "[*] Fetching Chromium sources"
  mkdir -p chromium
  pushd chromium
  git config --global core.precomposeUnicode true
  fetch --nohooks --no-history chromium
  popd
elif [ "$2" != "no-update" ]; then
  status "[*] Updating Chromium sources"
  pushd chromium/src
  git rebase-update
  popd
fi

# Stop here if we just wanted to fetch the code
if [ "$2" = "fetch-only" ]; then
  exit 0
fi

# Install additional build dependencies
if [ $FIRST_BUILD -eq 1 ] && [ "$(uname -s)" = "Linux" ]; then
  status "[*] Installing build dependencies"
  pushd chromium/src
  ./build/install-build-deps.sh \
    --no-arm --no-chromeos-fonts --no-nacl \
    --no-prompt
  popd
fi

# Run the hooks
pushd chromium/src
if [ $FIRST_BUILD -eq 1 ]; then
  status "[*] Running hooks"
  gclient runhooks
elif [ "$2" != "no-update" ]; then
  status "[*] Running hooks"
  gclient sync
fi
popd

# Configure the build
if [ ! -d chromium/src/out/Default ]; then
  status "[*] Configuring"
  pushd chromium/src
  mkdir -p out/Default
  (echo "enable_nacl = false"; echo "symbol_level = 0") > out/Default/args.gn
  gn gen out/Default
  popd
fi

# Build Courgette
status "[*] Building Courgette"
pushd chromium/src
autoninja -C out/Default courgette
popd
touch .first-build-finished

# Create the version string
pushd chromium/src
DATE=$(date +"%Y%m%d")
GITHASH=$(git rev-parse --short HEAD)
VERSION="1.0.0-${DATE}+${GITHASH}"
popd

# Build the Debian package on Linux
if [ "$(uname -s)" = "Linux" ]; then
  status "[*] Creating Debian package"
  
  # Copy the packaging template into the workspace
  rm -rf courgette
  cp -r "$(dirname "$0")"/deb-package courgette
  
  # Copy the Courgette binary into the package
  mkdir -p courgette/usr/bin
  cp chromium/src/out/Default/courgette courgette/usr/bin
  
  # Copy all built libraries it depends on in as well
  mkdir -p courgette/usr/lib
  LIBDEPS=$(ldd chromium/src/out/Default/courgette \
    | grep 'chromium' \
    | awk '{ print $3 }')
  cp $LIBDEPS courgette/usr/lib
  
  # Patch up the control file
  ARCH=$(dpkg --print-architecture)
  sed -i \
    -e "s/@VERSION@/$VERSION/g" \
    -e "s/@ARCH@/$ARCH/g" \
    courgette/DEBIAN/control
  
  # Build the package
  dpkg-deb --build courgette
  mv courgette.deb "courgette-linux_${VERSION}_${ARCH}.deb"
  rm -rf courgette
fi

# Build a zip archive on macOS
if [ "$(uname -s)" = "Darwin" ]; then
  status "[*] Creating archive"
  
  # Create the archive directory
  rm -rf courgette
  mkdir courgette
  
  # Copy the courgette binary into the directory
  cp chromium/src/out/Default/courgette courgette
  LIBDEPS=$(otool -L chromium/src/out/Default/courgette \
    | grep '@rpath' \
    | awk '{ print $1 }' \
    | sed 's,@rpath/,chromium/src/out/Default/,g')
  cp $LIBDEPS courgette
  
  # Make the zip archive
  ARCH=$(uname -m)
  zip -r "courgette-mac_${VERSION}_${ARCH}.zip" courgette
  rm -rf courgette
fi
