FROM registry.access.redhat.com/ubi8/ubi
RUN dnf -y --disableplugin=subscription-manager install \
      http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/centos-repos-8.1-1.1911.0.8.el8.x86_64.rpm \
      http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/centos-gpg-keys-8.1-1.1911.0.8.el8.noarch.rpm && \
    dnf -y --disableplugin=subscription-manager module enable mod_auth_openidc && \
    dnf --disableplugin=subscription-manager -y install httpd mod_auth_openidc && \
    dnf --disableplugin=subscription-manager clean all

# Fix permissions so that httpd can run in the restricted scc
RUN chgrp root /var/run/httpd && chmod g+rwx /var/run/httpd  && \
    chgrp root /var/log/httpd && chmod g+rwx /var/log/httpd

# Remove any existing configs in conf.d and don't try to bind to port 80
RUN rm -f /etc/httpd/conf.d/* && \
    sed -i '/^Listen 80/d' /etc/httpd/conf/httpd.conf

EXPOSE 8080

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
