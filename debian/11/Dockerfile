# Multi-stage Dockerfile for Debian with systemd
# Usage: docker build --build-arg DEBIAN_VERSION=11 -t debian-systemd:11 .

ARG DEBIAN_VERSION=bullseye-slim
FROM debian:${DEBIAN_VERSION}

# Metadata
LABEL maintainer="Edino Moniz <edinomoniz@gmail.com>"
LABEL description="Debian ${DEBIAN_VERSION} with systemd"

# 1. Install essential packages (dbus added) and clean up
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        findutils \
        iproute2 \
        python3 \
        python3-apt \
        sudo \
        systemd \
        dbus \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 2. Remove unnecessary systemd services that don't work well in containers
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

# 3. Mask services that aren't needed in containers
RUN systemctl mask \
    dev-hugepages.mount \
    sys-fs-fuse-connections.mount \
    systemd-remount-fs.service \
    getty.target \
    console-getty.service

# 4. Create volume for systemd's cgroup hierarchy
VOLUME [ "/sys/fs/cgroup" ]

# Set the default command to systemd
CMD ["/lib/systemd/systemd"]
