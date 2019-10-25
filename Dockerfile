FROM centos/httpd:latest
MAINTAINER ManageIQ https://github.com/ManageIQ/manageiq-appliance-build

## Set build ARGs
ARG DBUS_API_REF=master

## Systemd
ENV container oci

## Atomic/OpenShift Labels
LABEL name="auth-httpd" \
      vendor="ManageIQ" \
      url="http://manageiq.org/" \
      summary="httpd image with external authentication" \
      description="An httpd image which includes packages and configuration necessary for handling external authentication." \
      io.k8s.display-name="Httpd with Authentication" \
      io.k8s.description="An httpd image which includes packages and configuration necessary for handling external authentication." \
      io.openshift.expose-services="80:http" \
      io.openshift.tags="httpd"

## To cleanly shutdown systemd, use SIGRTMIN+3
STOPSIGNAL SIGRTMIN+3

## Install EPEL repo, yum necessary packages for the build without docs, clean all caches
RUN yum -y install centos-release-scl-rh && \
    yum -y install --setopt=tsflags=nodocs mod_ssl                      \
                                           && \
    # SSSD Packages \
    yum -y install --setopt=tsflags=nodocs sssd                         \
                                           sssd-dbus                    \
                                           && \
    # Apache External Authentication Module Packages \
    yum -y install --setopt=tsflags=nodocs mod_auth_kerb                \
                                           mod_auth_gssapi              \
                                           mod_authnz_pam               \
                                           mod_intercept_form_submit    \
                                           mod_lookup_identity          \
                                           mod_auth_mellon              \
                                           mod_auth_openidc             \
                                           && \
    # IPA External Authentication Packages \
    yum -y install --setopt=tsflags=nodocs c-ares                       \
                                           certmonger                   \
                                           ipa-client                   \
                                           ipa-admintools               \
                                           && \
    # Active Directory External Authentication Packages \
    yum -y install --setopt=tsflags=nodocs adcli                        \
                                           realmd                       \
                                           oddjob                       \
                                           oddjob-mkhomedir             \
                                           samba-common                 \
                                           samba-common-tools           \
                                           && \
    yum clean all

## Systemd cleanup base image
RUN (cd /lib/systemd/system/sysinit.target.wants && for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -vf $i; done) & \
     rm -vf /lib/systemd/system/multi-user.target.wants/* && \
     rm -vf /etc/systemd/system/*.wants/* && \
     rm -vf /lib/systemd/system/local-fs.target.wants/* && \
     rm -vf /lib/systemd/system/sockets.target.wants/*udev* && \
     rm -vf /lib/systemd/system/sockets.target.wants/*initctl* && \
     rm -vf /lib/systemd/system/basic.target.wants/* && \
     rm -vf /lib/systemd/system/anaconda.target.wants/*

## Remove any existing configurations
RUN rm -f /etc/httpd/conf.d/*

## For ruby
ENV RUBY_GEMS_ROOT=/usr/local/lib/ruby/gems/2.5.0 \
    LANG=en_US.UTF-8

# Install repos
RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    curl -sL https://copr.fedorainfracloud.org/coprs/manageiq/ManageIQ-Master/repo/epel-7/manageiq-ManageIQ-Master-epel-7.repo -o /etc/yum.repos.d/manageiq.repo

# Install ruby-install and make
RUN yum -y install --setopt=tsflags=nodocs ruby-install make

RUN ruby-install --system ruby 2.5.7 -- --disable-install-doc --enable-shared && rm -rf /usr/local/src/* && yum clean all

## Install DBus API Service
ENV HTTPD_DBUS_API_SERVICE_DIRECTORY=/opt/dbus_api_service
RUN mkdir -p ${HTTPD_DBUS_API_SERVICE_DIRECTORY}
RUN cd ${HTTPD_DBUS_API_SERVICE_DIRECTORY} && \
    curl -L https://github.com/ManageIQ/dbus_api_service/tarball/${DBUS_API_REF} | tar vxz -C ${HTTPD_DBUS_API_SERVICE_DIRECTORY} --strip 1 && \
    gem install bundler && \
    bundle install
COPY container-assets/dbus-api.service    /usr/lib/systemd/system/dbus-api.service

## Create the mount point for the authentication configuration files
RUN mkdir /etc/httpd/auth-conf.d

COPY container-assets/save-container-environment /usr/bin
COPY container-assets/initialize-httpd-auth.sh   /usr/bin

COPY container-assets/initialize-httpd-auth.service /usr/lib/systemd/system/initialize-httpd-auth.service

## Make sure sssd has the right startup conditions
RUN  mkdir -p /etc/systemd/system/sssd.service.d
COPY container-assets/sssd-startup.conf /etc/systemd/system/sssd.service.d/startup.conf

## Make sure httpd has the environment variables needed for external auth
RUN  mkdir -p /etc/systemd/system/httpd.service.d
COPY container-assets/httpd-environment.conf /etc/systemd/system/httpd.service.d/environment.conf

## Copy the pages that must be served by this httpd and cannot be proxied.
RUN mkdir -p /var/www/html/proxy_pages
COPY container-assets/invalid_sso_credentials.js /var/www/html/proxy_pages/

EXPOSE 80

WORKDIR /etc/httpd

RUN systemctl enable initialize-httpd-auth sssd httpd dbus-api

VOLUME /sys/fs/cgroup

CMD [ "/usr/sbin/init" ]
