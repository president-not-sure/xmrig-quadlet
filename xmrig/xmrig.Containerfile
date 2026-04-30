FROM quay.io/fedora/fedora:latest AS build

# Installing build dependencies
RUN dnf install -y \
        git \
        make \
        cmake \
        gcc \
        gcc-c++ \
        libstdc++-static \
        automake \
        libtool \
        autoconf \
        perl-FindBin \
        perl-IPC-Cmd \
        wget \
        tree

COPY xmrig.patch /tmp

# Build XMRig
RUN git clone --depth=1 https://github.com/xmrig/xmrig.git /xmrig && \
    cd /xmrig && \
    git apply --verbose /tmp/xmrig.patch && \
    mkdir -p /xmrig/build && \
    cd /xmrig/scripts && \
    ./build_deps.sh && \
    cd /xmrig/build && \
    cmake .. -DXMRIG_DEPS=/xmrig/scripts/deps && \
    make -j"$(nproc)" && \
    echo "The following shared libraries are required by XMRig:" && \
    ldd /xmrig/build/xmrig

# Staging XMRig
RUN install -vD -m 755 -t /staging/app /xmrig/build/xmrig && \
    dnf --use-host-config --installroot=/staging -y install glibc

FROM scratch

COPY --from=build /staging /

ENTRYPOINT [ "/app/xmrig" ]
