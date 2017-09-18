#!/bin/bash

HTTPD_AUTH_CONFIG_DIR=/etc/httpd/auth-conf.d
AUTH_CONFIG_FILE="${HTTPD_AUTH_CONFIG_DIR}/auth-configuration.conf"

function trim_whitespace {
  sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

function auth_files {
  if [ -f ${AUTH_CONFIG_FILE} ]
  then
    grep '^file[[:space:]]*=.*$' ${AUTH_CONFIG_FILE} | cut -f2 -d= | trim_whitespace
  fi
}

AUTH_TYPE=${HTTPD_AUTH_TYPE:-internal}
echo "Authentication Type: ${AUTH_TYPE}"

if [ "${AUTH_TYPE}" == "internal" ]
then
  echo "No External Authentication Defined."
  exit 0
fi

echo "Initializing $AUTH_TYPE External Authentication"

echo "Copying Authentication Files:"
auth_files | \
(
  while read source_file target_file file_permission
  do
    BINARY=""; [[ ${source_file} =~ \.base64$ ]] && BINARY="BINARY"
    printf "Copying: %s => %s (%s) %s\n" ${source_file} ${target_file} ${file_permission:-unspecified} $BINARY
    TARGET_DIR="`dirname ${target_file}`"
    [[ ! -d "${TARGET_DIR}" ]] && /usr/bin/mkdir -p "${TARGET_DIR}"
    if [ -n "${BINARY}" ]
    then
      cat ${HTTPD_AUTH_CONFIG_DIR}/${source_file} | /usr/bin/base64 -d > ${target_file}
    else
      cp ${HTTPD_AUTH_CONFIG_DIR}/${source_file} ${target_file}
    fi
    if [ $? -ne 0 ]
    then
      echo "Failed to copy file ${target_file}" >&2
      exit 1
    fi
    PERMS=(`echo $file_permission | awk -F: '{print $1, $2, $3}'`)
    [[ -n "${PERMS[0]}" ]] && /usr/bin/chmod ${PERMS[0]} ${target_file}
    [[ -n "${PERMS[1]}" ]] && /usr/bin/chown ${PERMS[1]} ${target_file}
    [[ -n "${PERMS[2]}" ]] && /usr/bin/chgrp ${PERMS[2]} ${target_file}
  done
)
echo "Finished copying Authentication Files."

exit 0
