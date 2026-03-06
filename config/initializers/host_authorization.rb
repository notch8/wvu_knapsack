# Allow requests from WVU library domains and localhost variants.
# Rails 7.2 HostAuthorization matches Regexp against raw_host_with_port
# (which includes the port, e.g. "admin-wvu_knapsack.localhost.direct:3000"),
# so patterns must accommodate an optional trailing port.
Rails.application.config.hosts << /\.lib\.wvu\.edu(:\d+)?\z/
Rails.application.config.hosts << /\.localhost\.direct(:\d+)?\z/
Rails.application.config.hosts << /\Alocalhost(:\d+)?\z/

# hyrax-webapp's production.rb hard-codes config.force_ssl = true, which causes
# HTTP→HTTPS redirect loops when running the stack locally without an SSL-
# terminating reverse proxy. Set DISABLE_FORCE_SSL=true in .env.production to
# strip the ActionDispatch::SSL middleware for local compose testing.
# On a real deployment the CDN/LB terminates SSL and this var should be absent
# (or set to false) — or better yet, a proper SSL proxy handles termination.
if ENV['DISABLE_FORCE_SSL'] == 'true'
  Rails.application.config.middleware.delete ActionDispatch::SSL
end
