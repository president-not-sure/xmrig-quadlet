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
RUN git clone --depth=1 https://github.com/MoneroOcean/xmrig.git /xmrig && \
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
RUN install -vD -m 755 -t /staging/app \
        /xmrig/build/xmrig && \
    install -vD -m 755 -t /staging/lib64 \
        /lib64/libm.so* \
        /lib64/libc.so* \
        /lib64/ld-linux-x86-64.so* && \
    echo "Staging tree before copying it to the final image:" && \
    tree -a /staging

FROM scratch

COPY --from=build /staging /

ENTRYPOINT [ "/app/xmrig" ]
