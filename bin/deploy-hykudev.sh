#!/usr/bin/env bash
set -euo pipefail

## Instructions:
## 0. Alias is already created and persisted at ~/.bashrc:
##    alias dc='dotenv -e .env.development docker-compose'
## 1. Connect to WVU VPN via The Windows App
## 2. Connect via PuTTY to hykudev server: hykudev.lib.wvu.edu with your user name
## 3. Switch to ansible: sudo su - ansible
## 4. cd wvu_knapsack
## 5. ./deploy_hykudev.sh [optional-branch-name]

PROJECT_ROOT="/home/ansible/wvu_knapsack"
HYRAX_APP_DIR="$PROJECT_ROOT/hyrax-webapp"
RESTORE_FILES=("Gemfile.lock" "config/metadata_profiles/m3_profile.yaml")

log() { echo -e "$1"; }
die() { echo -e "❌ $1" >&2; exit 1; }

log "📁 Switching to project root..."
cd "$PROJECT_ROOT" || die "Project root not found: $PROJECT_ROOT"

# --- prereq checks ---
command -v git >/dev/null 2>&1 || die "git not found on PATH"
command -v dc  >/dev/null 2>&1 || die "'dc' command not found. Ensure your alias is loaded (source ~/.bashrc) and dotenv is installed."
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not a git repository: $PROJECT_ROOT"

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"
log "📌 Deploying branch: $BRANCH"

log "🔎 Fetching latest refs..."
git fetch --all --prune

# Ensure we have the branch locally; if not, try to track origin/<branch>
if ! git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
    log "🌿 Creating local branch '$BRANCH' tracking origin/$BRANCH..."
    git checkout -b "$BRANCH" "origin/$BRANCH"
  else
    die "Branch '$BRANCH' not found locally or on origin."
  fi
else
  git checkout "$BRANCH"
fi

log "🔄 Pulling latest code for '$BRANCH'..."
git pull --ff-only origin "$BRANCH" || die "Failed to pull branch '$BRANCH' (non-fast-forward?)."

# If you *always* want main updates too, keep this; otherwise remove it.
if [ "$BRANCH" != "main" ]; then
  log "ℹ️ Note: You're deploying '$BRANCH'. If this branch needs new commits from 'main', merge/rebase it before deploying."
fi

log "📦 Syncing & updating submodules..."
git submodule sync --recursive
git submodule update --init --recursive --remote

log "🏷️ Updating TAG to latest commit SHA..."
TAG="$(git rev-parse --short=8 HEAD)"
export TAG
log "🔖 TAG: $TAG"

log "🧹 Stopping and cleaning up old containers..."
dc down --remove-orphans

log "🔄 Resetting selected files to match repository..."
if [ -d "$HYRAX_APP_DIR" ]; then
  cd "$HYRAX_APP_DIR"
  git restore "${RESTORE_FILES[@]}" || die "Failed to restore one or more files in hyrax-webapp."
  cd "$PROJECT_ROOT"
else
  die "Expected directory not found: $HYRAX_APP_DIR"
fi

log "🐳 Pulling latest Docker images..."
dc pull

log "🚀 Building and starting containers..."
dc build solr
dc up -d web

log "✅ Deploy complete. Containers are now running image tagged: $TAG"
log ""
log "🔗 Admin Tenant:   https://hykudev-admin.lib.wvu.edu"
log "🔗 Default Tenant: https://hykudev.lib.wvu.edu"
