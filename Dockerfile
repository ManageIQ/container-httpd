FROM centos/httpd:latest
MAINTAINER ManageIQ https://github.com/ManageIQ/manageiq-appliance-build

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
    # SSSD Packages \
    yum -y install --setopt=tsflags=nodocs sssd                         \
                                           sssd-dbus                    \
                                           && \
    # Apache External Authentication Module Packages \
    yum -y install --setopt=tsflags=nodocs mod_auth_kerb                \
                                           mod_authnz_pam               \
                                           mod_intercept_form_submit    \
                                           mod_lookup_identity          \
                                           mod_auth_mellon              \
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
                                           real-md                      \
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

## For Ruby
ENV TERM=xterm \
    LANG=en_US.UTF-8 \
    RUBY_GEMS_ROOT=/opt/rubies/ruby-2.3.1/lib/ruby/gems/2.3.0 \
    PATH=$PATH:/opt/rubies/ruby-2.3.1/bin

# Install repos
RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    curl -sL https://copr.fedorainfracloud.org/coprs/postmodern/ruby-install/repo/fedora-25/postmodern-ruby-install-fedora-25.repo -o /etc/yum.repos.d/ruby-install.repo && \
    sed -i 's/\$releasever/25/g' /etc/yum.repos.d/ruby-install.repo

# Install ruby-install and make
RUN yum -y install --setopt=tsflags=nodocs ruby-install make

# Install Ruby 2.3.1
RUN ruby-install ruby 2.3.1 -- --disable-install-doc && rm -rf /usr/local/src/* && yum clean all

## Build Auth-Api
ENV HTTPD_AUTH_API_SERVICE_DIRECTORY=/opt/auth-api
RUN mkdir -p ${HTTPD_AUTH_API_SERVICE_DIRECTORY}
COPY docker-assets/auth-api ${HTTPD_AUTH_API_SERVICE_DIRECTORY}
RUN  cd ${HTTPD_AUTH_API_SERVICE_DIRECTORY} && \
     gem install bundler && \
     bundle install
COPY docker-assets/auth-api.service    /usr/lib/systemd/system/auth-api.service

## Create the mount point for the authentication configuration files
RUN mkdir /etc/httpd/auth-conf.d

COPY docker-assets/save-container-environment /usr/bin
COPY docker-assets/initialize-httpd-auth.sh   /usr/bin

COPY docker-assets/initialize-httpd-auth.service /usr/lib/systemd/system/initialize-httpd-auth.service

## Make sure sssd has the right startup conditions
RUN  mkdir -p /etc/systemd/system/sssd.service.d
COPY docker-assets/sssd-startup.conf /etc/systemd/system/sssd.service.d/startup.conf

## Make sure httpd has the environment variables needed for external auth
RUN  mkdir -p /etc/systemd/system/httpd.service.d
COPY docker-assets/httpd-environment.conf /etc/systemd/system/httpd.service.d/environment.conf

EXPOSE 80

WORKDIR /etc/httpd

RUN systemctl enable initialize-httpd-auth sssd httpd auth-api

VOLUME /sys/fs/cgroup

CMD [ "/usr/sbin/init" ]
