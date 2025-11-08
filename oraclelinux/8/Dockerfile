# Multi-stage Dockerfile for Oracle Linux with systemd
# Usage: docker build --build-arg ORACLELINUX_VERSION=8 -t oraclelinux-systemd:8 .

ARG ORACLELINUX_VERSION=10
FROM oraclelinux:${ORACLELINUX_VERSION}

# Metadata
LABEL maintainer="Edino Moniz <edinomoniz@gmail.com>"
LABEL description="Oracle Linux ${ORACLELINUX_VERSION} with systemd"

ENV container=docker

# Enable Python 3.11 module and install systemd + Python
RUN dnf install -y python3.11 python3.11-devel systemd && \
    alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    yum clean all && \
    rm -rf /var/cache/yum

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
