#!/usr/bin/env bash
set -euo pipefail

## Instructions:
## 0. Alias was already created and persisted at ~/.bashrc:
##    alias dc='dotenv -e .env.development docker-compose'
## 1. Connect to WVU VPN via The Windows App
## 2. Connect via PuTTY to hykudev server: hykudev.lib.wvu.edu with your user name
## 3. Switch to ansible: sudo su - ansible
## 4. cd wvu_knapsack
## 5. ./deploy_hykudev.sh [optional-branch-name]

PROJECT_ROOT="/home/ansible/wvu_knapsack"
HYRAX_APP_DIR="$PROJECT_ROOT/hyrax-webapp"

log() { echo -e "$1"; }
die() { echo -e "❌ $1" >&2; exit 1; }

cd "$PROJECT_ROOT" || die "Project root not found: $PROJECT_ROOT"

command -v dc >/dev/null 2>&1 || die "'dc' not found. Make sure your alias is loaded (source ~/.bashrc)."
command -v git >/dev/null 2>&1 || die "git not found on PATH"

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"
log "📌 Deploying branch: $BRANCH"

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
  log "🔄 Restoring known files in hyrax-webapp (pre-submodule update)..."
  git -C "$HYRAX_APP_DIR" restore Gemfile.lock config/metadata_profiles/m3_profile.yaml 2>/dev/null || true
fi

log "📦 Updating submodules..."
git submodule sync --recursive
git submodule update --init --recursive --remote

TAG="$(git rev-parse --short=8 HEAD)"
export TAG
log "🔖 TAG: $TAG"

log "🧹 Restarting containers..."
dc down --remove-orphans
dc pull
dc up -d web

log "✅ Deploy complete (TAG: $TAG)"
log "🔗 Admin Tenant:   https://hykudev-admin.lib.wvu.edu"
log "🔗 Default Tenant: https://hykudev.lib.wvu.edu"
