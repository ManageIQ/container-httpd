FROM manageiq/ruby
MAINTAINER ManageIQ https://github.com/ManageIQ/manageiq-appliance-build

## For SUI
ARG REF=master

## Set ENV, LANG only needed if building with docker-1.8
ENV container=docker \
    CONTAINER=true \
    APACHE_CONF_DIR=/etc/httpd/conf.d \
    APP_ROOT=/var/www/miq/vmdb \
    PERSISTENT=/persistent \
    APPLIANCE_ROOT=/opt/manageiq/manageiq-appliance \
    SUI_ROOT=/opt/manageiq/manageiq-ui-service \
    CONTAINER_SCRIPTS_ROOT=/opt/manageiq/container-scripts \
    TERM=xterm

## Atomic/OpenShift Labels
LABEL name="manageiq-apache" \
      vendor="ManageIQ" \
      version="2.4.6-45" \
      url="http://manageiq.org/" \
      summary="ManageIQ appliance apache image" \
      description="ManageIQ is a management and automation platform for virtual, private, and hybrid cloud infrastructures." \
      io.k8s.display-name="ManageIQ Apache" \
      io.k8s.description="ManageIQ Apache is the front-end for the ManageIQ Appliance." \
      io.openshift.expose-services="443:https" \
      io.openshift.tags="ManageIQ-Apache,apache"

## To cleanly shutdown systemd, use SIGRTMIN+3
STOPSIGNAL SIGRTMIN+3

## Install EPEL repo, yum necessary packages for the build without docs, clean all caches
RUN yum -y install centos-release-scl-rh && \
    yum -y install --setopt=tsflags=nodocs \
                   git                     \
                   net-tools               \
                   nodejs                  \
                   httpd                   \
                   mod_ssl                 \
                   mod_auth_kerb           \
                   mod_authnz_pam          \
                   mod_intercept_form_submit \
                   mod_lookup_identity     \
                   mod_auth_mellon         \
                   initscripts             \
                   npm                     \
                   openldap-clients        \
                   http-parser             \
                   ipa-client              \
                   ipa-admintools          \
                   certmonger              \
                   sssd                    \
                   sssd-dbus               \
                   c-ares                  \
                   real-md                 \
                   adcli                   \
                   oddjob                  \
                   oddjob-mkhomedir        \
                   realmd                  \
                   samba-common            \
                   &&                      \
    yum clean all

# Systemd cleanup base image
RUN (cd /lib/systemd/system/sysinit.target.wants && for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -vf $i; done) && \
     rm -vf /lib/systemd/system/multi-user.target.wants/* && \
     rm -vf /etc/systemd/system/*.wants/* && \
     rm -vf /lib/systemd/system/local-fs.target.wants/* && \
     rm -vf /lib/systemd/system/sockets.target.wants/*udev* && \
     rm -vf /lib/systemd/system/sockets.target.wants/*initctl* && \
     rm -vf /lib/systemd/system/basic.target.wants/* && \
     rm -vf /lib/systemd/system/anaconda.target.wants/*

## GIT clone manageiq-appliance and service UI repo (SUI)
RUN mkdir -p ${APPLIANCE_ROOT} && \
    curl -L https://github.com/ManageIQ/manageiq-appliance/tarball/${REF} | tar vxz -C ${APPLIANCE_ROOT} --strip 1
RUN mkdir -p ${SUI_ROOT} && \
    curl -L https://github.com/ManageIQ/manageiq-ui-service/tarball/${REF} | tar vxz -C ${SUI_ROOT} --strip 1

## Setup environment
RUN ${APPLIANCE_ROOT}/setup && \
    rm -f /etc/httpd/conf.d/manageiq-balancer-* && \
    ln -vs ${APP_ROOT} /opt/manageiq/manageiq && \
    mkdir -p ${APP_ROOT}/log && \
    mkdir -p ${APP_ROOT}/public && \
    ln -s /persistent-assets/assets ${APP_ROOT}/public/assets && \
    mkdir -p ${CONTAINER_SCRIPTS_ROOT} && \
    mv /etc/httpd/conf.d/ssl.conf{,.orig} && \
    echo "# This file intentionally left blank. ManageIQ maintains its own SSL configuration" > /etc/httpd/conf.d/ssl.conf 

## Change workdir to application root, build/install gems
WORKDIR ${APP_ROOT}

## Build SUI
RUN cd ${SUI_ROOT} && \
    npm install yarn -g && \
    yarn install --production && \
    yarn run build && \
    yarn cache clean

## Expose required container ports
EXPOSE 80 443

## Copy Apache configuration files
COPY docker-assets/apache-conf/*.conf /etc/httpd/conf.d/

## Copy OpenShift and appliance-initialize scripts
COPY docker-assets/entrypoint /usr/bin
COPY docker-assets/container.data.persist /
COPY docker-assets/appliance-initialize.sh /bin
ADD  docker-assets/container-scripts ${CONTAINER_SCRIPTS_ROOT}

RUN systemctl enable dbus httpd

VOLUME [ "/sys/fs/cgroup" ]

ENTRYPOINT [ "entrypoint" ]
CMD [ "/usr/sbin/init" ]
