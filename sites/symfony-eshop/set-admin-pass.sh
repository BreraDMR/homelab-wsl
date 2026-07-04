#!/usr/bin/env bash
set -e
PASS="$1"
HASH=$(docker exec eshop-php php bin/console security:hash-password "$PASS" 2>/dev/null | grep -oE '\$(2[aby]|argon2i?d?)\S+' | head -1)
if [ -z "$HASH" ]; then echo "failed to generate hash"; exit 1; fi
echo "hash prefix: ${HASH:0:12}"
docker exec eshop-db psql -U eshop -d eshop -c "UPDATE users SET password='$HASH' WHERE email='admin@example.com';"
