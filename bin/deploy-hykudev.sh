#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="/home/ansible/wvu_knapsack"
HYRAX_APP_DIR="$PROJECT_ROOT/hyrax-webapp"

log() { echo -e "$1"; }
die() { echo -e "$1" >&2; exit 1; }

# ✅ Make dc deterministic in scripts (do NOT rely on aliases)
dc() { dotenv -e .env.development docker compose "$@"; }

cd "$PROJECT_ROOT" || die "Project root not found: $PROJECT_ROOT"

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"
log "Deploying branch: $BRANCH"

git fetch --all --prune

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git checkout "$BRANCH"
elif git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  git checkout -b "$BRANCH" "origin/$BRANCH"
else
  die "Branch '$BRANCH' not found locally or on origin."
fi

git pull --ff-only origin "$BRANCH" || die "Failed to pull '$BRANCH' (non-fast-forward?)"

if [ -d "$HYRAX_APP_DIR" ]; then
  git -C "$HYRAX_APP_DIR" restore Gemfile.lock config/metadata_profiles/m3_profile.yaml 2>/dev/null || true
fi

log "Updating submodules..."
git submodule sync --recursive
git submodule update --init --recursive --remote

# --- tags ---
export SOLR_TAG="latest"
export APP_TAG="$(git rev-parse --short=8 HEAD)"

log "APP_TAG:  $APP_TAG"
log "SOLR_TAG: $SOLR_TAG"

log "Restarting containers..."
dc down --remove-orphans

log "Pulling images..."
dc pull

log "Starting services..."
dc up -d web


log "Deploy complete (TAG: $TAG)"
log "Admin Tenant:   https://hykudev-admin.lib.wvu.edu"
log "Default Tenant: https://hykudev.lib.wvu.edu"
