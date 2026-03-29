#!/bin/sh

load_local_env_file() {
  env_file=$1
  PREPARED_NORMALIZED_ENV_FILE=

  if [ -n "$env_file" ] && [ -f "$env_file" ]; then
    PREPARED_NORMALIZED_ENV_FILE=$(mktemp "${TMPDIR:-/tmp}/udm-acme-env.XXXXXX")
    tr -d '\r' < "$env_file" > "$PREPARED_NORMALIZED_ENV_FILE"
  fi

  if [ -n "$PREPARED_NORMALIZED_ENV_FILE" ]; then
    set -a
    . "$PREPARED_NORMALIZED_ENV_FILE"
    set +a
    rm -f "$PREPARED_NORMALIZED_ENV_FILE"
    PREPARED_NORMALIZED_ENV_FILE=
  fi
}