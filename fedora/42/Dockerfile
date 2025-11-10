# Multi-stage Dockerfile for Fedora with systemd
# Usage: docker build --build-arg FEDORA_VERSION=42 -t fedora-systemd:42 .

ARG FEDORA_VERSION=42
FROM fedora:${FEDORA_VERSION}

# Metadata
LABEL maintainer="Edino Moniz <edinomoniz@gmail.com>"
LABEL description="Fedora ${FEDORA_VERSION} with systemd"

ENV container=docker

# Install systemd and Python
RUN dnf update -y && \
    dnf install -y python3 python3-devel systemd && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# Remove unnecessary systemd services
WORKDIR /etc/systemd/system/sysinit.target.wants/
RUN for i in * ; do [ "$i" = systemd-tmpfiles-setup.service ] || rm -f "$i" ; done ; \
    rm -f /lib/systemd/system/multi-user.target.wants/* ; \
    rm -f /etc/systemd/system/*.wants/* ; \
    rm -f /lib/systemd/system/local-fs.target.wants/* ; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev* ; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl* ; \
    rm -f /lib/systemd/system/basic.target.wants/* ; \
    rm -f /lib/systemd/system/anaconda.target.wants/*

WORKDIR /

VOLUME ["/sys/fs/cgroup"]

CMD ["/usr/sbin/init"]
