# build an environment for building and running qemu on x86-64 to emulate loongarch

FROM ubuntu:20.04

RUN export DEBIAN_FRONTEND=noninteractive && \
    sed -i -e 's/archive.ubuntu.com/mirrors.163.com/' /etc/apt/sources.list && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install --no-install-recommends -y \
            bash \
            bc \
            bzip2 \
            ca-certificates \
            dbus \
            debianutils \
            diffutils \
            exuberant-ctags \
            findutils \
            g++ \
            gcc \
            gettext \
            git \
            hostname \
            libaio-dev \
            libattr1-dev \
            libbrlapi-dev \
            libbz2-dev \
            libc6-dev \
            libcapstone-dev \
            libcurl4-gnutls-dev \
            libdrm-dev \
            libfdt-dev \
            libffi-dev \
            libfuse3-dev \
            libgbm-dev \
            libgcrypt20-dev \
            libglib2.0-dev \
            libgtk-3-dev \
            libjpeg-turbo8-dev \
            libncursesw5-dev \
            libpam0g-dev \
            libpcre2-dev \
            libpixman-1-dev \
            libpulse-dev \
            libslirp-dev \
            libspice-protocol-dev \
            libspice-server-dev \
            libssh-dev \
            locales \
            make \
            ninja-build \
            openssh-client \
            perl-base \
            pkgconf \
            python3 \
            python3-numpy \
            python3-pip \
            python3-setuptools \
            python3-yaml \
            sed \
            zlib1g-dev && \
    apt-get autoremove -y && \
    apt-get autoclean -y && \
    sed -Ei 's,^# (zh_CN\.UTF-8 .*)$,\1,' /etc/locale.gen && \
    dpkg-reconfigure locales && \
    dpkg-query --showformat '${Package}_${Version}_${Architecture}\n' --show > /packages.txt 

RUN pip3 install \
         meson==0.56.0

# please download them into current directory first
ADD qemu.tar.gz /opt/
ADD loongarch64-clfs-2021-12-18-cross-tools-gcc-full.tar.xz /opt/

RUN mkdir /workspace

ENV LANG "zh_CN.UTF-8"
ENV MAKE "/usr/bin/make"
ENV NINJA "/usr/bin/ninja"
ENV PYTHON "/usr/bin/python3"
ENV PATH "/bin:/sbin:/usr/bin:/usr/sbin:/opt/qemu/bin:/opt/cross-tools/bin"

WORKDIR /workspace
ADD *.S Makefile *.md /workspace/

