#!/usr/bin/env bash
# Create the shared external docker networks. Idempotent. Run once.
set -euo pipefail

if ! docker info >/dev/null 2>&1; then
  echo "docker is not answering. Inside WSL that usually means the service is" >&2
  echo "down: sudo service docker start   (or: systemctl start docker)" >&2
  exit 1
fi

for net in homelab_edge homelab_internal; do
  if docker network inspect "$net" >/dev/null 2>&1; then
    echo "network $net: exists"
  else
    echo "network $net: creating"
    docker network create "$net" >/dev/null
  fi
done
echo "bootstrap done."
