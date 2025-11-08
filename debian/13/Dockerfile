# Multi-stage Dockerfile for Debian with systemd
# Usage: docker build --build-arg DEBIAN_VERSION=12 -t debian-systemd:12 .

ARG DEBIAN_VERSION=13
FROM debian:${DEBIAN_VERSION}

# Metadata
LABEL maintainer="Edino Moniz <edinomoniz@gmail.com>"
LABEL description="Debian ${DEBIAN_VERSION} with systemd"

# 1. Install essential packages (dbus added) and clean up
RUN INSTALL_PKGS="findutils iproute2 python3 python3-apt sudo systemd dbus" \
    && apt-get update && apt-get install "${INSTALL_PKGS}" -y --no-install-recommends \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Remove unnecessary systemd services that don't work well in containers
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

# Mask services that aren't needed in containers
RUN systemctl mask \
    dev-hugepages.mount \
    sys-fs-fuse-connections.mount \
    systemd-remount-fs.service \
    getty.target \
    console-getty.service

# Create volume for systemd's cgroup hierarchy
VOLUME [ "/sys/fs/cgroup" ]

# Set the default command to systemd
CMD ["/lib/systemd/systemd"]
