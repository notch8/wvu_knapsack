#!/usr/bin/env sh
set -e

# Pull latest knapsack code before bringing up containers.
git pull

# Ensure the hyrax-webapp submodule is initialised and up to date.
# This is safe to run repeatedly and is required on a fresh VM clone.
git submodule update --init --recursive

# hyrax-webapp/.env.production must exist because the submodule's docker-compose
# declares it in env_file. It can be empty — real vars come from .env.production
# at the knapsack root. The submodule's .gitignore already covers .env.* so this
# file is invisible to submodule git tracking.
[ -f hyrax-webapp/.env.production ] || touch hyrax-webapp/.env.production

docker compose -f docker-compose.production.yml up -d
