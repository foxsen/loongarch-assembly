# build an environment to test loongarch assembly on PC platform via qemu

FROM ubuntu:20.04

RUN export DEBIAN_FRONTEND=noninteractive && \
    sed -i -e 's/archive.ubuntu.com/mirrors.163.com/' /etc/apt/sources.list && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install --no-install-recommends -y \
            make \
            vim \
            libglib2.0-0 \
            git && \
    apt-get autoremove -y && \
    apt-get autoclean -y 

# please download them into current directory first
ADD qemu-6.2.50.loongarch64.tar.gz /opt/
ADD loongarch64-clfs-3.0-cross-tools-gcc-glibc.tar.xz /opt/

RUN mkdir /workspace

ENV LANG "zh_CN.UTF-8"
ENV MAKE "/usr/bin/make"
ENV PATH "/bin:/sbin:/usr/bin:/usr/sbin:/opt/qemu/bin:/opt/cross-tools.gcc_glibc/bin"

WORKDIR /workspace
ADD *.S Makefile *.md *.c /workspace/
