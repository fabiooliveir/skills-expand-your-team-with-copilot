#!/usr/bin/env bash
# Per-boot startup: ensure MongoDB is running. The Cloud Agent VM has no systemd,
# so mongod is started directly. Idempotent: does nothing if already running.
set -euo pipefail

DBPATH="/var/lib/mongodb"
LOGPATH="/var/log/mongodb/mongod.log"

if pgrep -x mongod > /dev/null 2>&1; then
  echo "mongod already running"
  exit 0
fi

sudo mkdir -p "${DBPATH}" "$(dirname "${LOGPATH}")"
sudo chown -R mongodb:mongodb "${DBPATH}" "$(dirname "${LOGPATH}")" || true

sudo mongod --dbpath "${DBPATH}" --logpath "${LOGPATH}" --bind_ip 127.0.0.1 --fork

# Wait for MongoDB to accept connections.
for _ in $(seq 1 30); do
  if mongosh --quiet --eval "db.adminCommand('ping').ok" 2>/dev/null | grep -q 1; then
    echo "mongod is ready"
    exit 0
  fi
  sleep 1
done

echo "mongod failed to become ready" >&2
exit 1
