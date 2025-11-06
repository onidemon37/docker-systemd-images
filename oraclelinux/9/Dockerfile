FROM oraclelinux:9

LABEL maintainer="Edino Moniz <edino.moniz@sectigo.com>"

ENV container=docker

# Enable Python 3.11 module and install systemd + Python
RUN dnf install -y python3.11 python3.11-devel systemd && \
    alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    yum clean all && \
    rm -rf /var/cache/yum

# Remove unnecessary systemd services
RUN cd /etc/systemd/system/sysinit.target.wants/ ; \
    for i in * ; do [ $i = systemd-tmpfiles-setup.service ] || rm -f $i ; done ; \
    rm -f /lib/systemd/system/multi-user.target.wants/* ; \
    rm -f /etc/systemd/system/*.wants/* ; \
    rm -f /lib/systemd/system/local-fs.target.wants/* ; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev* ; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl* ; \
    rm -f /lib/systemd/system/basic.target.wants/* ; \
    rm -f /lib/systemd/system/anaconda.target.wants/*

VOLUME ["/sys/fs/cgroup"]

CMD ["/usr/sbin/init"]
