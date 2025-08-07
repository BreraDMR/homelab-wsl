#!/usr/bin/env bash
# What is actually running in the lab, on one screen.
# Answers the question you have at 1am: is it up, and which one died?
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

echo "== containers =="
docker compose ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null \
  || echo "compose not answering - is docker running?"

echo
echo "== networks =="
for net in homelab_edge homelab_internal; do
  if docker network inspect "$net" >/dev/null 2>&1; then
    n=$(docker network inspect -f '{{len .Containers}}' "$net")
    echo "$net: $n container(s)"
  else
    echo "$net: MISSING - run bin/bootstrap.sh"
  fi
done
