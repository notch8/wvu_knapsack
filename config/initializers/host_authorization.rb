# Allow requests from WVU library domains and localhost variants.
# Rails 7.2 HostAuthorization matches Regexp against raw_host_with_port
# (which includes the port, e.g. "admin-wvu_knapsack.localhost.direct:3000"),
# so patterns must accommodate an optional trailing port.
Rails.application.config.hosts << /\.lib\.wvu\.edu(:\d+)?\z/
Rails.application.config.hosts << /\.localhost\.direct(:\d+)?\z/
Rails.application.config.hosts << /\Alocalhost(:\d+)?\z/
