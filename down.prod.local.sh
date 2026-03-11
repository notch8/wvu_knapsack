#!/usr/bin/env sh
# Stop the local production smoke test stack. Data is preserved in ./data/.
#
# Usage:
#   sh down.prod.local.sh
set -e

docker compose -f docker-compose.local.yml down
