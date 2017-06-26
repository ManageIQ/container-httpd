#!/bin/bash
set -e -o pipefail

mkdir -p /etc/httpd/certs/
CERT="/etc/httpd/certs/server.cer"
KEY="$CERT.key"
if [ ! -f "$CERT" -a ! -f "$KEY" ]; then
  (umask 077 ; openssl req -x509 -newkey rsa -days 1095 -keyout $KEY -out $CERT -subj "/CN=server" -nodes -batch)
fi
