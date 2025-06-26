#!/bin/bash
set -e

if [ "$(whoami)" != "ansible" ]; then
  echo "⛔ Not running as 'ansible'. Switching..."
  exec sudo su - ansible
else
  echo "✅ Already running as 'ansible'. Continuing..."
fi

cd /home/ansible/wvu_knapsack/hyrax-webapp
git restore Gemfile.lock
cd /home/ansible/wvu_knapsack

BRANCH="${1}"

echo "🔄 Pulling latest code from 'main'..."
git pull origin main

if [ -n "$BRANCH" ]; then
  echo "🔄 Also pulling latest code from branch '$BRANCH'..."
  git pull origin "$BRANCH"
fi

echo "🏷️  Updating TAG to latest commit SHA"
TAG=$(git rev-parse --short=8 HEAD)

echo "📦 Loading .env.development..."
set -a
source .env.development
export TAG
set +a

echo "🐳 Pulling new image(s)..."
docker compose pull

echo "🏗️ Building new image(s)..."
docker compose build

echo "🔁 Restarting only updated containers..."
docker compose up -d

echo "✅ Deploy complete. Containers are now running image tagged: $TAG"