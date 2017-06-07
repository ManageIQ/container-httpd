#!/bin/bash

# This directory is used to store apache specific logfiles on PV
PV_LOG_DIR="${PERSISTENT}/log"

# This directory is used to store apache specific configuration on PV
PV_CONFIG_DIR="${PERSISTENT}/config"

# Prepare appliance initialization environment
function prepare_init_env() {
  # Create container deployment dirs into PV if not already present
  mkdir -p "${PV_CONFIG_DIR}"
}

# Configure EVM logdir on PV
function setup_logs() {
  # Ensure Apache logdir is setup on PV and symlinked from Vmdb
  mkdir -p "${PV_LOG_DIR}"
  chmod 777 "${PV_LOG_DIR}"
  if [ ! -h "${APP_ROOT}/log/apache" ]; then
    ln --backup -sn "${PV_LOG_DIR}" "${APP_ROOT}/log/apache"
  fi
}

# Generate server certificates
function generate_server_certificates() {
  CERT_DIR="${PERSISTENT}/certs"
  mkdir -p ${CERT_DIR}
  if [ ! -h "${APP_ROOT}/certs" ]; then
    ln --backup -sn "${CERT_DIR}" "${APP_ROOT}/certs"
  fi
  /usr/bin/generate_miq_server_cert.sh
}

