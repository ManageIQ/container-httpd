#!/usr/bin/bash
SSSD_CONF="/etc/sssd/sssd.conf"
if [ -f $SSSD_CONF ]
then
  echo "Config file $SSSD_CONF found, enabling and starting SSSD."
  systemctl enable sssd
  systemctl start  sssd
else
  echo "No $SSSD_CONF config file found, not enabling SSSD."
fi
