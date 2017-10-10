FROM fedora
MAINTAINER Matthew Booth <mbooth@redhat.com>

### Basic Fedora minimal install container using systemd
## Based off the upstream rawhide one

ENV container docker
ARG mirror

# Configure the build to use a specific Fedora mirror if one was given
RUN if [ ! -z "$mirror" ]; then \
    dnf -y install fedrepos && fedrepos baseurl --no-metalink "$mirror"; fi

RUN dnf -y groupinstall "Minimal Install"
RUN dnf -y update

RUN dnf -y install systemd && dnf clean all && \
    (cd /lib/systemd/system/sysinit.target.wants/; \
     for i in *; do \
         [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; \
     done \
    ); \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*;

VOLUME [ "/sys/fs/cgroup" ]
ENTRYPOINT ["/usr/sbin/init"]

### Additional utility packages

RUN dnf -y install git vim-enhanced

### Openstack pre-installation
## stack.sh will run this all again, which will update anything out-of-date,
## but this saves a ton of time

# Pre-install all the openstack dependencies we know about
# We use strict=0 here because by default dnf will do nothing if any package in
# the list can't be installed.
RUN for i in ceph \
             cinder \
             dstat \
             general \
             horizon \
             keystone \
             ldap \
             n-cpu \
             n-novnc \
             n-spice \
             neutron-agent \
             neutron-common \
             neutron-l3 \
             nova \
             openvswitch \
             swift; do \
         curl -s https://git.openstack.org/cgit/openstack-dev/devstack/plain/files/rpms/$i | sed 's/\s.*//'; \
     done | xargs -- dnf -y --setopt=strict=0 install

# Install pip dependencies which aren't pulled in automatically by the above
# python-nss
RUN dnf -y install nss-devel
# libvirt-python
RUN dnf -y install libvirt-devel
# PyECLib
RUN dnf -y install liberasurecode-devel

# Pre-install all openstack's python dependencies
# Except qpid-python and pyngus because they pull in python-qpid-proton, and
# proton doesn't support OpenSSL >= 1.1.0
# qpid-python is installed later somehow in a manner I don't understand
RUN curl -s https://git.openstack.org/cgit/openstack/requirements/plain/global-requirements.txt | \
    grep -v -E '(qpid-python|pyngus)' | \
    pip install -r /dev/stdin -r https://git.openstack.org/cgit/openstack/requirements/plain/test-requirements.txt \
        -c https://git.openstack.org/cgit/openstack/requirements/plain/upper-constraints.txt

### Configure a persistent stack user

VOLUME ["/home"]
RUN useradd stack
RUN echo "stack ALL=(ALL:ALL) NOPASSWD: ALL" | EDITOR="tee -a" visudo
