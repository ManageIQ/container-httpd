FROM centos/httpd:latest

MAINTAINER ManageIQ https://github.com/ManageIQ/manageiq-appliance-build

## Atomic/OpenShift Labels
LABEL name="manageiq-apache" \
      vendor="ManageIQ" \
      url="http://manageiq.org/" \
      summary="ManageIQ httpd image" \
      description="ManageIQ is a management and automation platform for virtual, private, and hybrid cloud infrastructures." \
      io.k8s.display-name="ManageIQ Apache" \
      io.k8s.description="ManageIQ Apache is the front-end for the ManageIQ Application." \
      io.openshift.expose-services="80:http" \
      io.openshift.tags="ManageIQ-Apache,apache"

## Install EPEL repo, yum necessary packages for the build without docs, clean all caches
RUN yum -y install centos-release-scl-rh && \
    yum clean all

## Remove any existing configurations
RUN rm -f /etc/httpd/conf.d/*

COPY docker-assets/entrypoint /usr/bin
COPY docker-assets/manageiq.conf /etc/httpd/conf.d/

EXPOSE 80

ENTRYPOINT [ "entrypoint" ]
CMD ["/run-httpd.sh"]
