FROM manageiq/manageiq-pods:app-latest

MAINTAINER ManageIQ https://github.com/ManageIQ/manageiq-appliance-build

## Set ENV, LANG only needed if building with docker-1.8
ENV APACHE_CONF_DIR=/etc/httpd/conf.d \
    APP_ROOT=/var/www/miq/vmdb \
    PERSISTENT=/persistent

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
                   httpd                   \
                   initscripts             \
                   mod_ssl                 \
                   npm                     \
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

## Setup apache
RUN rm -f /etc/httpd/conf.d/manageiq-balancer-* && \
    mv /etc/httpd/conf.d/ssl.conf{,.orig} && \
    echo "# This file intentionally left blank. ManageIQ maintains its own SSL configuration" > /etc/httpd/conf.d/ssl.conf 

## Change workdir to application root, build UI components
WORKDIR ${APP_ROOT}
RUN source /etc/default/evm && \
    export RAILS_USE_MEMORY_STORE="true" && \
    npm install bower yarn -g && \
    rake update:bower && \
    bin/rails log:clear tmp:clear && \
    rake evm:compile_assets && \
    # Cleanup install artifacts
    npm cache clean && \
    bower cache clean && \
    rm -rvf ${APP_ROOT}/tmp/cache/assets && \
    rm -vf ${APP_ROOT}/log/*.log

# Build SUI
RUN cd ${SUI_ROOT} && \
    yarn install --production && \
    yarn run build && \
    yarn cache clean

## Expose required container ports
EXPOSE 80 443

## Copy Apache configuration files
COPY docker-assets/apache-conf/*.conf /etc/httpd/conf.d/

## Copy OpenShift and appliance-initialize scripts
COPY docker-assets/entrypoint /usr/bin
COPY docker-assets/appliance-initialize.sh /bin
ADD  docker-assets/container-scripts ${CONTAINER_SCRIPTS_ROOT}

RUN systemctl enable dbus httpd

VOLUME [ "/sys/fs/cgroup" ]

ENTRYPOINT [ "entrypoint" ]
CMD [ "/usr/sbin/init" ]
