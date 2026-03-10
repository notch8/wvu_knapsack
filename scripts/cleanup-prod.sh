#!/bin/bash
# Nuclear Option for production stacks (local smoke test or VM).
# Tears down containers, removes named volumes, wipes ./data bind mounts,
# and removes locally built images — scoped to this project only.
#
# Usage:
#   sh scripts/cleanup-prod.sh         # local production smoke test (docker-compose.local.yml)
#   sh scripts/cleanup-prod.sh vm      # VM production (docker-compose.production.yml)
#
# After running, restart with:
#   docker compose -f docker-compose.local.yml up -d          (local)
#   sh up.sh                                                   (vm)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

if [[ "${1:-}" == "vm" ]]; then
  COMPOSE_FILE="docker-compose.production.yml"
  ENV_FILE_ARGS="--env-file .env.production"
  # VM builds images locally — only remove local images, not pulled base images
  RMI_MODE="local"
  IS_VM=true
else
  COMPOSE_FILE="docker-compose.local.yml"
  ENV_FILE_ARGS=""
  # Local smoke test pulls GHCR images — remove all so a fresh pull happens on next up
  RMI_MODE="all"
  IS_VM=false
fi

echo "==> Stopping stack ($COMPOSE_FILE) and removing project volumes + images..."
# shellcheck disable=SC2086
docker compose $ENV_FILE_ARGS -f "$COMPOSE_FILE" down --rmi "$RMI_MODE" -v --remove-orphans 2>/dev/null || true

echo "==> Wiping ./data bind mounts (DB, Solr, Fedora, uploads, bundle cache, etc.)..."
rm -rf ./data

echo "==> Pruning dangling images and build cache..."
docker image prune -f
docker builder prune -f

if [[ "$IS_VM" == true ]]; then
  echo ""
  echo "==> Re-creating ./data and restoring SELinux label (RHEL only)..."
  mkdir -p ./data
  if command -v chcon &>/dev/null; then
    sudo chcon -Rt svirt_sandbox_file_t ./data
    echo "    SELinux label applied."
  else
    echo "    chcon not found — skipping SELinux label (not on RHEL)."
  fi
fi

echo ""
echo "Done. All wvu_knapsack data has been removed."
echo ""
if [[ "$IS_VM" == true ]]; then
  echo "To restart:"
  echo "  sh up.sh"
  echo "  docker compose -f docker-compose.production.yml exec web sh /app/samvera/scripts/setup.sh"
else
  echo "To restart:"
  echo "  docker compose -f docker-compose.local.yml up -d"
  echo "  docker compose -f docker-compose.local.yml logs -f initialize_app"
  echo "  docker compose -f docker-compose.local.yml exec web sh /app/samvera/scripts/setup.sh"
fi
