#!/bin/bash

#
# Initial setup for httpd upon container startup.
#

# Define container environment variables needed by the httpd process
#
cat - <<!END! >> /etc/sysconfig/httpd

#
# Container Environment Variables needed
#
MANAGEIQ_SERVICE_NAME = "${MANAGEIQ_SERVICE_NAME}"
!END!

