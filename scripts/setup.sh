#!/bin/sh
# setup.sh - one-time production setup for wvu_knapsack
#
# Run this inside the web container after the stack is healthy:
#   docker-compose -f docker-compose.production.yml exec web sh /app/samvera/scripts/setup.sh
#
# The knapsack root (.) is already bind-mounted at /app/samvera in the web
# container, so this script is available there without any extra volume config.
#
# This script is idempotent: safe to re-run.

set -e
cd /app/samvera/hyrax-webapp

echo ""
echo "=== wvu_knapsack production setup ==="
echo ""

# ------------------------------------------------------------
# 1. Asset precompilation
# ------------------------------------------------------------
# NOTE: assets:precompile also runs automatically inside initialize_app before
# the web container starts. Re-running setup.sh forces a recompile (e.g. after
# changing asset files). The web container must be restarted afterwards to pick
# up the new manifest: docker-compose -f docker-compose.production.yml restart web
echo "--- [1/4] Asset precompilation ---"
# Idempotent - safe to re-run; existing assets are overwritten in place.
RAILS_ENV=production bin/rails assets:precompile
echo ""

# ------------------------------------------------------------
# 2. Database
# ------------------------------------------------------------
echo "--- [2/4] Database setup ---"

# Create the DB if it doesn't exist yet (no-op if already exists)
bin/rails db:create 2>&1 || true

# If the schema_migrations table already exists, the DB has been initialized
# before - just migrate. Otherwise load the schema from scratch.
TABLES=$(bin/rails runner "puts ActiveRecord::Base.connection.tables.length" 2>/dev/null || echo "0")
if [ "$TABLES" -gt 0 ] 2>/dev/null; then
  echo "Database already initialized ($TABLES tables) - running migrations"
  bin/rails db:migrate
elif [ -e "db/schema.rb" ]; then
  echo "Fresh database with schema.rb - loading schema"
  DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:schema:load
else
  echo "Fresh database, no schema.rb - running migrations"
  DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:migrate
fi

echo "--- Seeding database ---"
bin/rails db:seed

echo ""

# ------------------------------------------------------------
# 3. Solr configset
# ------------------------------------------------------------
echo "--- [3/4] Solr configset ---"
solrcloud-upload-configset.sh /app/samvera/hyrax-webapp/solr/conf || true
solrcloud-assign-configset.sh || true

echo ""

# ------------------------------------------------------------
# 4. First repository tenant
# ------------------------------------------------------------
# NOTE: The admin host (HYKU_ADMIN_HOST) is intentionally NOT created as an
# Account record - Hyku routes admin requests separately and its cname is in
# the excluded list. Access the admin interface at https://$HYKU_ADMIN_HOST
# to create and manage tenant accounts through the UI.
#
# This step creates the first repository tenant from HYKU_FIRST_TENANT_NAME and
# HYKU_FIRST_TENANT_CNAME if they are set. Leave them unset to skip this step
# and create tenants manually via the admin UI.
echo "--- [4/4] First repository tenant ---"

if [ -z "${HYKU_FIRST_TENANT_NAME:-}" ] || [ -z "${HYKU_FIRST_TENANT_CNAME:-}" ]; then
  echo "HYKU_FIRST_TENANT_NAME or HYKU_FIRST_TENANT_CNAME not set - skipping"
  echo "Create tenant accounts via the admin UI at https://$HYKU_ADMIN_HOST"
else
  bin/rails runner - << RUBY
name = ENV.fetch('HYKU_FIRST_TENANT_NAME')
cname = ENV.fetch('HYKU_FIRST_TENANT_CNAME')
if Account.where(cname: cname).exists?
  puts "Tenant already exists: \#{cname} - skipping"
else
  account = Account.new(name: name, cname: cname)
  if CreateAccount.new(account).save
    puts "Created tenant: \#{account.cname}"
  else
    \$stderr.puts "FAILED to create tenant: \#{account.errors.full_messages.join(', ')}"
    exit 1
  end
end
RUBY
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "Admin interface: https://$HYKU_ADMIN_HOST"
echo "  Email:         $INITIAL_ADMIN_EMAIL"
echo "  Password:      $INITIAL_ADMIN_PASSWORD"
echo ""
