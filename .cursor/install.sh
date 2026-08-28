#!/usr/bin/env bash
# Idempotent dependency setup for the Mergington High School Activities app.
# Installs system build tools, MongoDB Community Edition, and Python packages.
set -euo pipefail

MONGODB_MAJOR="8.0"
KEYRING="/usr/share/keyrings/mongodb-server-${MONGODB_MAJOR}.gpg"
SOURCE_LIST="/etc/apt/sources.list.d/mongodb-org-${MONGODB_MAJOR}.list"
UBUNTU_CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"

sudo apt-get update -qq
# build-essential + python3-dev are required to compile the legacy argon2==0.1.10 C extension.
sudo apt-get install -y -qq build-essential python3-dev curl gnupg ca-certificates

# Add the official MongoDB apt repository (only if not already configured).
if [ ! -f "${KEYRING}" ]; then
  curl -fsSL "https://www.mongodb.org/static/pgp/server-${MONGODB_MAJOR}.asc" \
    | sudo gpg -o "${KEYRING}" --dearmor --yes
fi
echo "deb [ arch=amd64,arm64 signed-by=${KEYRING} ] https://repo.mongodb.org/apt/ubuntu ${UBUNTU_CODENAME}/mongodb-org/${MONGODB_MAJOR} multiverse" \
  | sudo tee "${SOURCE_LIST}" > /dev/null

sudo apt-get update -qq
sudo apt-get install -y -qq mongodb-org

# Install Python dependencies (--break-system-packages: system Python is PEP 668 managed).
pip3 install --break-system-packages -r src/requirements.txt

echo "install.sh completed successfully"
