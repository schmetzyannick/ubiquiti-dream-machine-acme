#!/bin/sh

set -eu

cd /workspace

[ -f ./bin/renew-cert.sh ] || {
  printf '%s\n' 'error: expected project to be mounted at /workspace' >&2
  exit 1
}

usage() {
  cat <<EOF
Usage:
  docker-entrypoint.sh issue
  docker-entrypoint.sh renew
  docker-entrypoint.sh deploy
  docker-entrypoint.sh issue-deploy
  docker-entrypoint.sh renew-deploy
EOF
}

ACTION=${1:-issue}

case $ACTION in
  help|-h|--help)
    usage
    exit 0
    ;;
  issue|renew)
    shift || true
    exec ./bin/renew-cert.sh "$ACTION" "$@"
    ;;
  *)
    usage >&2
    printf '%s\n' "error: unknown action: $ACTION" >&2
    exit 1
    ;;
esac
