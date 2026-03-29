#!/bin/sh

set -eu

SCRIPT_NAME=${0##*/}
acme_runtime_dir=
acme_sh=

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

require_env() {
  var_name=$1
  eval "var_value=\${$var_name-}"
  [ -n "$var_value" ] || die "missing required environment variable: $var_name"
}

cleanup_runtime() {
  if [ -n "$acme_runtime_dir" ] && [ -d "$acme_runtime_dir" ]; then
    rm -rf "$acme_runtime_dir"
  fi
}

load_local_env() {
  load_local_env_file "$PROJECT_ROOT/config/local.env"
}

prepare_acme_runtime() {
  prepare_filesystem "$CERTIFICATES_DIR" "${TMPDIR:-/tmp}/udm-acme.XXXXXX"
  acme_runtime_dir=$PREPARED_ACME_RUNTIME_DIR
  acme_sh=$PREPARED_ACME_SH
}

ensure_acme_sh() {
  command_exists curl || die "curl is required to download acme.sh"

  require_env ACME_ACCOUNT_EMAIL

  log "installing acme.sh into $acme_runtime_dir"
  curl -fsSL https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh | sh -s -- \
    --install-online \
    --home "$acme_runtime_dir" \
    --config-home "$acme_runtime_dir" \
    --cert-home "$acme_runtime_dir" \
    --accountemail "$ACME_ACCOUNT_EMAIL" \
    --no-cron \
    --no-profile

  [ -x "$acme_sh" ] || die "acme.sh installation failed"
}

register_account() {
  require_env ACME_ACCOUNT_EMAIL

  set -- "$acme_sh" --home "$acme_runtime_dir" --server letsencrypt --register-account -m "$ACME_ACCOUNT_EMAIL"
  "$@"
}

stage_certificate() {
  set -- "$acme_sh" --home "$acme_runtime_dir" --install-cert -d "$CERT_DOMAIN"

  set -- "$@" \
    --key-file "$CERTIFICATES_DIR/privkey.pem" \
    --fullchain-file "$CERTIFICATES_DIR/fullchain.pem" \
    --cert-file "$CERTIFICATES_DIR/cert.pem" \
    --ca-file "$CERTIFICATES_DIR/chain.pem"
  "$@"
}

obtain_certificate() {
  require_env ACME_ACCOUNT_EMAIL
  require_env CERT_DOMAIN
  require_env DNS_PROVIDER

  register_account

  set -- "$acme_sh" --home "$acme_runtime_dir" --issue --server letsencrypt --keylength 2048 --dns "$DNS_PROVIDER" -d "$CERT_DOMAIN"
  "$@"
  stage_certificate
}

issue_certificate() {
  obtain_certificate
}

renew_certificate() {
  obtain_certificate
}

usage() {
  cat <<EOF
Usage:
  $SCRIPT_NAME issue
  $SCRIPT_NAME renew

Environment:
  ACME_ACCOUNT_EMAIL  Required
  CERT_DOMAIN         Required domain name
  DNS_PROVIDER        Required, example dns_ionos

Provider credentials:
  Export the variables required by your chosen acme.sh DNS provider.
EOF
}

ACTION=${1:-help}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
PREPARE_FILESYSTEM_SH=$PROJECT_ROOT/bin/prepare-filesystem.sh
LOAD_LOCAL_ENV_SH=$PROJECT_ROOT/bin/load-local-env.sh
CERTIFICATES_DIR=$PROJECT_ROOT/certificates

. "$PREPARE_FILESYSTEM_SH"
. "$LOAD_LOCAL_ENV_SH"

trap cleanup_runtime EXIT INT TERM

case $ACTION in
  help|-h|--help)
    usage
    exit 0
    ;;
esac

case $ACTION in
  issue|renew)
    ;;
  *)
    die "unknown action: $ACTION"
    ;;
esac

load_local_env
prepare_acme_runtime
ensure_acme_sh

case $ACTION in
  issue)
    issue_certificate
    ;;
  renew)
    renew_certificate
    ;;
esac
