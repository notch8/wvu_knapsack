#!/usr/bin/env bash
set -euo pipefail

## Instructions:
## 0. Alias was already created and persisted at ~/.bashrc:
##    alias dc='dotenv -e .env.development docker-compose'
## 1. Connect to WVU VPN via The Windows App
## 2. Connect via PuTTY to hykudev server: hykudev.lib.wvu.edu with your user name
## 3. Switch to ansible: sudo su - ansible
## 4. cd wvu_knapsack
## 5. git pull origin main (or branch name)
## 6. ./bin/deploy_hykudev.sh

echo "Updating submodules..."
git submodule sync --recursive
git submodule update --init --recursive

echo "Stopping and cleaning up old containers..."
docker compose down --remove-orphans

echo "Pulling Docker images..."
TAG="$(git rev-parse --short=8 HEAD)" dotenv -e .env.development docker compose pull

echo "Building and starting containers..."
TAG="$(git rev-parse --short=8 HEAD)" dotenv -e .env.development docker compose up -d web

echo "Deploy complete. Containers are now running image tagged"
echo ""
echo "Admin Tenant:   https://hykudev-admin.lib.wvu.edu"
echo "Default Tenant: https://hykudev.lib.wvu.edu"