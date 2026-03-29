#!/bin/sh

prepare_filesystem() {
  certificates_dir=$1
  acme_runtime_template=$2

  PREPARED_ACME_RUNTIME_DIR=
  PREPARED_ACME_SH=

  if [ -n "$certificates_dir" ]; then
    mkdir -p "$certificates_dir"
  fi

  if [ -n "$acme_runtime_template" ]; then
    PREPARED_ACME_RUNTIME_DIR=$(mktemp -d "$acme_runtime_template")
    PREPARED_ACME_SH=$PREPARED_ACME_RUNTIME_DIR/acme.sh
  fi
}