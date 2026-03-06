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
# 1. Database
# ------------------------------------------------------------
echo "--- [1/3] Database setup ---"

if [ -e "db/schema.rb" ]; then
  echo "schema.rb found - loading schema"
  bin/rails db:create db:schema:load
else
  echo "No schema.rb - running migrations"
  bin/rails db:create db:migrate
fi

echo "--- Seeding database ---"
bin/rails db:seed

echo ""

# ------------------------------------------------------------
# 2. Solr configset
# ------------------------------------------------------------
echo "--- [2/3] Solr configset ---"
solrcloud-upload-configset.sh /app/samvera/hyrax-webapp/solr/conf || true
solrcloud-assign-configset.sh || true

echo ""

# ------------------------------------------------------------
# 3. Admin tenant Account record
# ------------------------------------------------------------
echo "--- [3/3] Admin tenant ---"

bin/rails runner - << 'RUBY'
admin_host = Account.admin_host
if Account.where(cname: admin_host).exists?
  puts "Admin tenant already exists: #{admin_host} - skipping"
else
  account = Account.new(name: 'WVU Knapsack Admin', cname: admin_host)
  if CreateAccount.new(account).save
    puts "Created admin tenant: #{account.cname}"
  else
    $stderr.puts "FAILED to create admin tenant: #{account.errors.full_messages.join(', ')}"
    exit 1
  end
end
RUBY

echo ""
echo "=== Setup complete ==="
echo ""
echo "Log in at: https://$HYKU_ADMIN_HOST"
echo "  Email:    $INITIAL_ADMIN_EMAIL"
echo "  Password: $INITIAL_ADMIN_PASSWORD"
echo ""
