# Multi-stage Dockerfile for Debian with systemd
# Usage: docker build --build-arg DEBIAN_VERSION=12 -t debian-systemd:12 .

ARG DEBIAN_VERSION=buster-slim
FROM debian:${DEBIAN_VERSION}

LABEL maintainer="Edino Moniz <edino.moniz@sectigo.com>"
LABEL description="Debian 10 (Buster) with systemd and Python 3.11 for Molecule testing"

ENV container=docker \
    SYSTEMD_IN_CONTAINER=yes \
    DEBIAN_FRONTEND=noninteractive \
    PYTHON_VERSION=3.11.9

# 1. Switch APT sources to the archive mirror for EOL Debian 10 (Buster)
RUN echo "deb http://archive.debian.org/debian buster main" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive

# 2. Install essential packages and build dependencies
RUN INSTALL_PKGS="findutils iproute2 sudo systemd dbus ca-certificates" \
    BUILD_DEPS='wget build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev \
                libncursesw5-dev libxml2-dev libxmlsec1-dev \
                libffi-dev liblzma-dev' \
    && apt-get update \
    && apt-get install $INSTALL_PKGS $BUILD_DEPS -y --no-install-recommends \
    # Download and build Python 3.11
    && cd /tmp \
    && wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz \
    && tar -xf Python-${PYTHON_VERSION}.tar.xz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-optimizations --with-ensurepip=install \
    && make -j $(nproc) \
    && make altinstall \
    && cd / \
    # Create symlinks for python3.11
    && ln -sf /usr/local/bin/python3.11 /usr/local/bin/python3 \
    && ln -sf /usr/local/bin/pip3.11 /usr/local/bin/pip3 \
    # Upgrade pip and install setuptools (needed for some Ansible modules)
    && pip3 install --no-cache-dir --upgrade pip setuptools wheel \
    # Clean up build dependencies and files
    && apt-get purge -y $BUILD_DEPS \
    && apt-get autoremove -y \
    && rm -rf /tmp/Python-${PYTHON_VERSION}* \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 3. Systemd cleanup: Remove only problematic unit links
RUN find /etc/systemd/system \
    /lib/systemd/system \
    -path '*.wants/*' \
    \( -name '*getty*' \
    -o -name '*systemd-logind*' \
    -o -name '*systemd-vconsole-setup*' \
    -o -name '*systemd-readahead*' \
    -o -name '*udev*' \) \
    -exec rm -v {} \; && \
    systemctl set-default multi-user.target

# 4. Mask services that aren't needed in containers
RUN systemctl mask \
    dev-hugepages.mount \
    sys-fs-fuse-connections.mount \
    systemd-remount-fs.service \
    getty.target \
    console-getty.service \
    systemd-logind.service

VOLUME ["/sys/fs/cgroup"]

# Use systemd as PID 1
CMD ["/lib/systemd/systemd"]
