#!/usr/bin/env sh
set -e

# Pull latest knapsack code before bringing up containers.
git pull

# Ensure the hyrax-webapp submodule is initialised and up to date.
# This is safe to run repeatedly and is required on a fresh VM clone.
# git submodule update --init --recursive

# hyrax-webapp/.env.production must exist because the submodule's docker-compose
# declares it in env_file. It can be empty — real vars come from .env.production
# at the knapsack root. The submodule's .gitignore already covers .env.* so this
# file is invisible to submodule git tracking.
[ -f hyrax-webapp/.env.production ] || touch hyrax-webapp/.env.production

# Ensure bind-mount directories exist and are writable by the container's app
# user (uid 1001, gid 101). Without this, bundle install fails with
# "Permission denied @ dir_s_mkdir - /usr/local/bundle" on a fresh clone
# where the directories are created by root.
# mkdir -p \
#   ./data/bundle \
#   ./data/node_modules \
#   ./data/assets \
#   ./data/cache \
#   ./data/uploads \
#   ./data/db \
#   ./data/solr \
#   ./data/zoo \
#   ./data/zk \
#   ./data/fcrepo \
#   ./data/redis \
#   ./data/logs/solr
# chown -R 1001:101 ./data/bundle ./data/node_modules ./data/assets ./data/cache

# Remove broken initializer from hyrax-webapp submodule if present.
# disable_solr.rb has a syntax error that aborts assets:precompile, and
# we do not want Solr disabled in production regardless.
rm -f ./hyrax-webapp/config/initializers/disable_solr.rb

docker compose --env-file .env.production -f docker-compose.production.yml up -d
