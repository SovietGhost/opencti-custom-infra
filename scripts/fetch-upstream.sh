#!/usr/bin/env bash
# Re-fetch the official OpenCTI docker files verbatim into ./opencti.
# Usage: scripts/fetch-upstream.sh [git-ref]   (default: master)
set -euo pipefail

REF="${1:-master}"
BASE="https://raw.githubusercontent.com/OpenCTI-Platform/docker/${REF}"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/opencti"

mkdir -p "$DEST"
for f in docker-compose.yml rabbitmq.conf .env.sample; do
  echo "fetching ${f} (${REF})"
  curl -fsSL "${BASE}/${f}" -o "${DEST}/${f}"
done
echo "OK -> ${DEST}"
