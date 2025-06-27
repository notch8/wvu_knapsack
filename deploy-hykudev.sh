#!/bin/bash

## Instructions
## Connect to WVU over VPN via The Windows App
## Login with your credentials given to you by the institution
## Open Windows PowerShell and ssh into the Virtual Machine (VM)
## Using your login credentials above (user_name@mail.wvu.edu/password)
# ssh user_name@hykudev.lib.wvu.edu
# At prompt enter your password
# sudo su - ansible
# cd wvu_knapsack
# ./deploy_hykudev.sh

set -e

# Add Notch8 developer alias
alias dc='docker compose'
alias dcb='docker compose build'

cd /home/ansible/wvu_knapsack/hyrax-webapp
git restore Gemfile.lock
cd /home/ansible/wvu_knapsack
git submodule update --remote

BRANCH="${1}"

echo "🔄 Pulling latest code from 'main'..."
git pull origin main

if [ -n "$BRANCH" ]; then
  echo "🔄 Also pulling latest code from branch '$BRANCH'..."
  git pull origin "$BRANCH"
fi

echo "🏷️ Updating TAG to latest commit SHA..."
TAG=$(git rev-parse --short=8 HEAD)
echo "Tag is: $TAG"

echo "📦 Loading base .env..."
set -a
[ -f .env ] && source .env

echo "📦 Overriding with .env.development..."
[ -f .env.development ] && source .env.development
set +a

export TAG

echo "🐳 Pulling new image(s)..."
docker compose pull

echo "🛑 Stopping and cleaning up old containers..."
docker compose down --remove-orphans

echo "🚀 Recreating with updated code..."
docker compose up -d --build

echo "✅ Deploy complete. Containers are now running image tagged: $TAG"
echo "Admin Tenant host: https://hykudev-admin.lib.wvu.edu"
echo "Hykudev Tenant https://hykudev.lib.wvu.edu"