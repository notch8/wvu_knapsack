# Allow requests from all WVU library production subdomains.
# A leading-dot string is matched against request.host (no port) as a suffix,
# so "*.lib.wvu.edu" hostnames (e.g. hyku.lib.wvu.edu) are permitted.
Rails.application.config.hosts << ".lib.wvu.edu"

# hyrax-webapp's production.rb hard-codes config.force_ssl = true.
# On the VM an SSL-terminating reverse proxy sits in front of the app and
# forwards plain HTTP, so force_ssl must remain on.
# If you ever need to run the production Rails env without an SSL proxy
# (e.g. smoke-testing a build), set DISABLE_FORCE_SSL=true in .env.production.
if ENV['DISABLE_FORCE_SSL'] == 'true'
  Rails.application.config.middleware.delete ActionDispatch::SSL
end
