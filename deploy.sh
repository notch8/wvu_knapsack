#!/bin/bash
set -e

cd /home/ansible/wvu_knapsack/

echo "🔄 Pulling latest code..."
git pull origin main

echo "🏷️  Updating TAG to latest commit SHA..."
TAG=$(git rev-parse --short=8 HEAD)
echo $TAG

echo "📦 Loading .env.development..."
set -a
source .env.development
export TAG
set +a

echo "🐳 Pulling new image(s)..."
docker compose pull

echo "🔁 Restarting only updated containers..."
docker compose up -d

echo "✅ Deploy complete. Containers are now running image tagged: $TAG"