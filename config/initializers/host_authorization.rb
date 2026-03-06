# Allow requests from WVU library production domains.
# Rails 7.2 HostAuthorization matches Regexp against raw_host_with_port
# (which includes the port number), so patterns use (:\d+)?\z.
Rails.application.config.hosts << /\.lib\.wvu\.edu(:\d+)?\z/

# hyrax-webapp's production.rb hard-codes config.force_ssl = true.
# On the VM an SSL-terminating reverse proxy sits in front of the app and
# forwards plain HTTP, so force_ssl must remain on.
# If you ever need to run the production Rails env without an SSL proxy
# (e.g. smoke-testing a build), set DISABLE_FORCE_SSL=true in .env.production.
if ENV['DISABLE_FORCE_SSL'] == 'true'
  Rails.application.config.middleware.delete ActionDispatch::SSL
end
