# Dockerfile for a container capable of building the Courgette target of
# Chromium.
#
# https://chromium.googlesource.com/chromium/src/+/master/docs/linux_build_instructions.md

FROM ubuntu:trusty

WORKDIR /root
VOLUME /root/out

# Install bootstrap dependencies
RUN apt-get update && apt-get install -y \
        curl \
        git \
        python

# Install depot_tools 
RUN git clone --depth 1 \
        https://chromium.googlesource.com/chromium/tools/depot_tools.git
ENV PATH=$PATH:/root/depot_tools

# Get the code
WORKDIR chromium
RUN fetch --nohooks --no-history chromium

# Install additional build dependencies
WORKDIR src
RUN ./build/install-build-deps.sh \
        --no-arm --no-chromeos-fonts --no-nacl \
        --no-prompt

# Run the hooks
RUN gclient runhooks

# Configure the build
RUN mkdir -p out/Default \
    && (echo "enable_nacl = false"; echo "symbol_level = 0") \
        >> out/Default/args.gn \
    && gn gen out/Default

# Copy in the build script
WORKDIR /root
COPY build.sh .
COPY packaging courgette
RUN chmod +x build.sh
CMD ["/root/build.sh"]
