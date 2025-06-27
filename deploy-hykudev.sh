#!/bin/bash

set -e

## Instructions:
## 1. Connect to WVU VPN via The Windows App
## 2. SSH into the VM: ssh user_name@hykudev.lib.wvu.edu
## 3. Switch to ansible: sudo su - ansible
## 4. cd wvu_knapsack
## 5. ./deploy_hykudev.sh [optional-branch-name]



echo "📁 Switching to project root..."
cd /home/ansible/wvu_knapsack

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"
echo "📌 Using branch: $BRANCH"

if [ "$BRANCH" != "main" ]; then
  echo "🔄 Pulling latest code from 'main'..."
  git pull origin main
  echo "🔄 Also pulling latest code from branch '$BRANCH'..."
  git pull origin "$BRANCH"
else
  echo "🔄 Pulling latest code from 'main'..."
  git pull origin main
fi

echo "📦 Updating submodules..."
git submodule update --remote

echo "🏷️ Updating TAG to latest commit SHA..."
TAG=$(git rev-parse --short=8 HEAD)
export TAG
echo "Tag is: $TAG"

echo "🧹 Stopping and cleaning up old containers..."
docker compose down --remove-orphans

echo "🔄 Resetting Gemfile.lock and m3_profile.yaml to match repository..."
cd /home/ansible/wvu_knapsack/hyrax-webapp
git restore Gemfile.lock config/metadata_profiles/m3_profile.yaml
cd ..

echo "🐳 Pulling latest Docker images..."
docker compose pull

echo "🚀 Recreating containers from latest image..."
docker compose build
docker compose up -d

echo "✅ Deploy complete. Containers are now running image tagged: $TAG"
echo ""
echo "🔗 Admin Tenant:   https://hykudev-admin.lib.wvu.edu"
echo "🔗 Default Tenant: https://hykudev.lib.wvu.edu"