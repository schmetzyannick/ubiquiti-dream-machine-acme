#!/bin/sh

prepare_filesystem() {
  env_file=$1
  certificates_dir=$2
  acme_runtime_template=$3

  PREPARED_NORMALIZED_ENV_FILE=
  PREPARED_ACME_RUNTIME_DIR=
  PREPARED_ACME_SH=

  if [ -n "$env_file" ] && [ -f "$env_file" ]; then
    command -v tr >/dev/null 2>&1 || die "tr is required"
    command -v mktemp >/dev/null 2>&1 || die "mktemp is required"

    PREPARED_NORMALIZED_ENV_FILE=$(mktemp "${TMPDIR:-/tmp}/udm-acme-env.XXXXXX")
    tr -d '\r' < "$env_file" > "$PREPARED_NORMALIZED_ENV_FILE"
  fi

  if [ -n "$certificates_dir" ]; then
    mkdir -p "$certificates_dir"
  fi

  if [ -n "$acme_runtime_template" ]; then
    command -v mktemp >/dev/null 2>&1 || die "mktemp is required"
    PREPARED_ACME_RUNTIME_DIR=$(mktemp -d "$acme_runtime_template")
    PREPARED_ACME_SH=$PREPARED_ACME_RUNTIME_DIR/acme.sh
  fi
}