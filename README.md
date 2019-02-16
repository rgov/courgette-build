# Courgette Builder

Google Chrome uses a binary patching tool called Courgette to provide efficient
software updates. The technology is described here:

https://www.chromium.org/developers/design-documents/software-updates-courgette

Courgette lives inside the Chromium repository and must be compiled using the
complex Chromium build system. It is not offered as an official standalone
installable package.

This repository describes a Docker container that builds Courgette for Linux 
x86_64.

    docker build -t courgette-build .
    docker run -v "$(pwd):/root/out" courgette-build

Each time the `docker run` command is executed, the latest Chromium sources are
fetched and built, and `courgette-{version}.deb` is created in the current
directory.

The Docker container image is very large, so when no longer needed, it can be 
deleted with:

    docker rmi courgette-build

Prebuilt packages may be found on the [release page][releases], but these are
not kept up to date.

[releases]: https://github.com/rgov/courgette-build/releases
