FROM debian:12 AS base

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        autotools-dev \
        bc \
        bison \
        build-essential \
        ccache \
        clang \
        cmake \
        curl \
        device-tree-compiler \
        flex \
        gawk \
        gcc gcc-multilib \
        git \
        gperf \
        help2man \
        libboost-regex-dev \
        libboost-system-dev \
        libc6 libc6:i386 \
        libexpat-dev \
        libfl-dev \
        libfl2 \
        libfreetype6 \
        libftdi1-dev \
        libglib2.0-dev \
        libgmp-dev \
        libgoogle-perftools-dev \
        libjim-dev \
        libmpc-dev \
        libmpfr-dev \
        libncurses5 libncurses5:i386 \
        libpixman-1-dev \
        libstdc++6 libstdc++6:i386 \
        libtinfo5 \
        libtool \
        libusb-1.0-0-dev \
        libxcursor1 \
        libxext6 libxext6:i386 \
        libxfixes3 \
        libxft2 libxft2:i386 \
        libxi6 \
        libxinerama1 \
        libxrandr2 \
        libxrender1 \
        libxtst6 \
        lld \
        locales \
        ninja-build \
        numactl \
        openssh-client \
        patchutils \
        perl \
        perl-doc \
        pkg-config \
        python3 \
        python3-pip \
        python3-venv \
        python3.11-dev \
        python3.11-full \
        texinfo \
        unzip \
        wget \
        xxd \
        zlib1g-dev \
    && \
    rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen

# Verilator Build =============================================================

FROM base AS verilator-build

ARG JOBS="1"

RUN git clone https://github.com/verilator/verilator.git && \
    cd verilator && \
    git checkout v5.008 && \
    autoconf && \
    ./configure --prefix=/usr/local && \
    make -j${JOBS} && \
    make install && \
    cd .. && \
    rm -rf verilator

# RISC-V Toolchain Build ======================================================

FROM base AS riscv-toolchain-build

ARG JOBS="1"

RUN git clone https://github.com/riscv/riscv-gnu-toolchain.git && \
    cd riscv-gnu-toolchain && \
    git checkout b8ca156d2ab0038c6af4569c52f9ec30d95342f0 && \
    ./configure --prefix=/opt/riscv \
        --enable-debug-info=yes \
        --disable-linux \
        --enable-llvm \
        --with-abi=ilp32 \
        --with-arch=rv32imc_zicsr \
        --with-cmodel=medlow \
    && \
    make -j${JOBS} && \
    cd .. && \
    rm -rf riscv-gnu-toolchain

# Spike Build =================================================================

FROM base AS spike-build

ARG JOBS="1"

RUN git clone https://github.com/riscv-software-src/riscv-isa-sim.git && \
    cd riscv-isa-sim && \
    git checkout 88fc84ded155a9e01987c4dfb7a77800e69b232b && \
    ./configure --prefix=/opt/riscv && \
    make -j${JOBS} && \
    make install && \
    cd .. && \
    rm -rf riscv-isa-sim

# OpenOCD Build ===============================================================

FROM base AS openocd-build

ARG JOBS="1"

RUN git clone https://github.com/riscv/riscv-openocd.git && \
    cd riscv-openocd && \
    git checkout 6e9514efcd0b5af1f5ffae5d1afa7e7640962ca6 && \
    ./bootstrap && \
    ./configure --prefix=/opt/riscv && \
    make -j${JOBS} && \
    make install && \
    cd .. && \
    rm -rf riscv-openocd

# Final Image =================================================================

FROM base AS final

COPY --from=verilator-build /usr/local /usr/local
COPY --from=riscv-toolchain-build /opt/riscv /opt/riscv
COPY --from=spike-build /opt/riscv /opt/riscv
COPY --from=openocd-build /opt/riscv /opt/riscv

WORKDIR /adam

COPY .bashrc /etc/bash.bashrc
