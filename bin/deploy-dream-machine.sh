#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
LOAD_LOCAL_ENV_SH=$PROJECT_ROOT/bin/load-local-env.sh
SCRIPT_NAME=${0##*/}

log() {
  printf '%s\n' "$*" >&2
}

die() {
  log "error: $*"
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_command() {
  command_name=$1
  error_message=$2

  if ! command_exists "$command_name"; then
    die "$error_message"
  fi
}

require_env() {
  var_name=$1
  eval "var_value=\${$var_name-}"
  [ -n "$var_value" ] || die "missing required environment variable: $var_name"
}

load_local_env() {
  load_local_env_file "$PROJECT_ROOT/config/local.env"
}

usage() {
  cat <<EOF
Usage:
  $SCRIPT_NAME

Environment:
  UDM_HOST            Required Dream Machine hostname or IP
  UDM_USER            Optional SSH user, default root
  UDM_PASSWORD        Required SSH password
  UDM_PORT            Optional SSH port, default 22
  UDM_CERT_DIR        Optional cert directory, default /data/unifi-core/config
  UDM_RESTART_COMMAND Optional restart command, default systemctl restart unifi-core

Certificate inputs:
  CERTIFICATES_DIR    Optional source directory, default ./certificates
EOF
}

. "$LOAD_LOCAL_ENV_SH"

if [ "${1:-}" = "help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

load_local_env

require_env UDM_HOST
require_env UDM_PASSWORD

require_command sshpass "sshpass is required for Dream Machine deployment; if you are running in Docker, rebuild the image with: docker build -t udm-acme ."
require_command ssh "ssh is required for Dream Machine deployment"
require_command scp "scp is required for Dream Machine deployment"

UDM_USER=${UDM_USER:-root}
UDM_PORT=${UDM_PORT:-22}
UDM_CERT_DIR=${UDM_CERT_DIR:-/data/unifi-core/config}
UDM_RESTART_COMMAND=${UDM_RESTART_COMMAND:-systemctl restart unifi-core}
CERTIFICATES_DIR=${CERTIFICATES_DIR:-$PROJECT_ROOT/certificates}
remote_target=$UDM_USER@$UDM_HOST

[ -f "$CERTIFICATES_DIR/fullchain.pem" ] || die "missing certificate file: $CERTIFICATES_DIR/fullchain.pem"
[ -f "$CERTIFICATES_DIR/privkey.pem" ] || die "missing key file: $CERTIFICATES_DIR/privkey.pem"

log "deploying certificate to $remote_target:$UDM_CERT_DIR"

SSHPASS=$UDM_PASSWORD sshpass -e scp -O -P "$UDM_PORT" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  "$CERTIFICATES_DIR/fullchain.pem" \
  "$remote_target:/tmp/unifi-core.crt"

SSHPASS=$UDM_PASSWORD sshpass -e scp -O -P "$UDM_PORT" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  "$CERTIFICATES_DIR/privkey.pem" \
  "$remote_target:/tmp/unifi-core.key"

SSHPASS=$UDM_PASSWORD sshpass -e ssh -p "$UDM_PORT" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  "$remote_target" \
  "install -m 644 /tmp/unifi-core.crt '$UDM_CERT_DIR/unifi-core.crt' && \
   install -m 600 /tmp/unifi-core.key '$UDM_CERT_DIR/unifi-core.key' && \
   rm -f /tmp/unifi-core.crt /tmp/unifi-core.key && \
   $UDM_RESTART_COMMAND"