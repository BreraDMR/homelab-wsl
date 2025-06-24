#!/usr/bin/env bash
# Grab the current sphynx quick-tunnel URL and write it as the README's
# managed first line in the site repo clone, then push to GitHub.
set -uo pipefail
APP="$HOME/homelab/sites/sphynx-cattery-website/app"
CONTAINER="sphynx-tunnel"
README="$APP/README.md"
MARKER="<!-- live-url -->"

URL=""
for i in $(seq 1 45); do
  URL=$(docker logs "$CONTAINER" 2>&1 | grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' | tail -1)
  [ -n "$URL" ] && break
  sleep 2
done
if [ -z "$URL" ]; then echo "publish: no tunnel URL found yet"; exit 0; fi

LINE="> 🌐 **Live demo (auto-updated each restart):** $URL  $MARKER"
if head -1 "$README" | grep -qF "$MARKER"; then
  tmp=$(mktemp); { printf '%s\n' "$LINE"; tail -n +2 "$README"; } > "$tmp"; mv "$tmp" "$README"
else
  tmp=$(mktemp); { printf '%s\n\n' "$LINE"; cat "$README"; } > "$tmp"; mv "$tmp" "$README"
fi

cd "$APP" || exit 0
if ! git diff --quiet -- README.md; then
  git add README.md
  git commit -q -m "chore: update live demo URL"
  if git push -q origin main; then echo "publish: pushed $URL"; else echo "publish: push FAILED"; fi
else
  echo "publish: URL unchanged ($URL)"
fi
