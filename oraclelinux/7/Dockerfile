# Dockerfile for Oracle Linux 7 with systemd
# Usage: docker build -t oraclelinux-systemd:7 .
#
# Unlike 8/9/10, this isn't parameterized via ORACLELINUX_VERSION - OL7 has
# no dnf at all (yum only), so it needs genuinely different package-install
# steps, not just a different tag on the same Dockerfile.

FROM oraclelinux:7

# Metadata
LABEL maintainer="Edino Moniz <edinomoniz@gmail.com>"
LABEL description="Oracle Linux 7 with systemd"

ENV container=docker

RUN yum install -y systemd python3 curl tar gzip && \
    yum clean all && \
    rm -rf /var/cache/yum

# OL7's own yum-provided python3 (3.6.8) is too old for modern ansible-core
# (needs 3.7+ - confirmed via a real build failure against Oracle's actual
# OL7.9 cloud image). Installing a portable, prebuilt Python 3.11 alongside
# it rather than gambling on a versioned yum package (python38/python39
# aren't available via this image's default repos, confirmed the same
# way). Left as /usr/bin/python3.11, not overwriting the system python3 -
# matches the real target exactly, and Ansible's own interpreter
# auto-discovery already prefers python3.11 over plain python3.
#
# Must match the build host's arch, not be hardcoded - a hardcoded x86_64
# download baked into an arm64 build produces a foreign-arch binary that
# only "runs" under Rosetta and crashes (confirmed: rc=133, rosetta error
# "failed to open elf at /lib64/ld-linux-x86-64.so.2").
RUN case "$(uname -m)" in \
      x86_64) PY_ARCH=x86_64-unknown-linux-gnu ;; \
      aarch64) PY_ARCH=aarch64-unknown-linux-gnu ;; \
      *) echo "Unsupported build architecture: $(uname -m)" >&2; exit 1 ;; \
    esac && \
    curl -sL -o /tmp/python311.tar.gz "https://github.com/astral-sh/python-build-standalone/releases/download/20260929/cpython-3.11.16%2B20260929-${PY_ARCH}-install_only.tar.gz" && \
    mkdir -p /opt/python3.11 && \
    tar -xzf /tmp/python311.tar.gz -C /opt/python3.11 --strip-components=1 && \
    ln -sf /opt/python3.11/bin/python3.11 /usr/bin/python3.11 && \
    rm -f /tmp/python311.tar.gz

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
