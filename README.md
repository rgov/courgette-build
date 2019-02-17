# Courgette Builder

Google Chrome uses a binary patching tool called Courgette to provide efficient
software updates. The technology is described here:

https://www.chromium.org/developers/design-documents/software-updates-courgette

Courgette lives inside the Chromium repository and must be compiled using the
complex Chromium build system. It is not offered as an official standalone
installable package.

This repository contains a build script that automates the process of compiling
Courgette.

Prebuilt packages may be found on the [release page][releases], but these are
not kept up to date.

[releases]: https://github.com/rgov/courgette-build/releases


## Debian and macOS

Please follow the [platform-specific guides][guides] on building Chromium to
install the initial dependencies such as `git`.

[guides]: https://www.chromium.org/developers/how-tos/get-the-code

The build script handles the rest:

    ./build.sh ./workspace

This produces a binary at `./workspace/chromium/src/out/Default/courgette`.

It also produces a Debian package at
`./workspace/courgette-linux_{version}-{date}+{revision}_{arch}.deb` for Linux 
builds, or a similarly-named zip archive for macOS builds.

Use `ldd` (Linux) or `otool -L` (macOS) to view which shared libraries that
Courgette links against, such as `libbase` and `libc++`.


## Debian, using a Docker container

You can construct a Docker container with all of the build dependencies ready
to go:

    ./build.sh ./workspace fetch-only
    cp ./workspace/chromium/src/build/install-build-deps.sh .
    docker build -t courgette-build .

To execute a build inside the container, run:

    docker run -v "$(pwd)/workspace:/ws" courgette-build

### macOS host notes

  - Docker makes a copy of the entire directory while building a container
    image. The `.dockerignore` file is configured to exclude `./workspace`, as
    a checkout of Chromium sources can easily exceed 10GB. If you use another
    workspace name, it is strongly advised to place it outside of this
    directory.

  - Using the same workspace for macOS and Docker-based Debian builds is
    currently not possible. It *may* be possible to clone a workspace created 
    with the `fetch-only` option before any further steps have been applied:

    ```
    ./build.sh ./workspace fetch-only
    cp -ca workspace workspace-linux
    ```
