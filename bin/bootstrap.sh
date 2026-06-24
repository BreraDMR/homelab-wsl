#!/usr/bin/env bash
# Create the shared external docker networks. Idempotent. Run once.
set -euo pipefail
for net in homelab_edge homelab_internal; do
  if docker network inspect "$net" >/dev/null 2>&1; then
    echo "network $net: exists"
  else
    echo "network $net: creating"
    docker network create "$net" >/dev/null
  fi
done
echo "bootstrap done."
