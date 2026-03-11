# frozen_string_literal: true

# Fix: Universal Viewer shows ERR_CONNECTION_REFUSED for IIIF image info.json
# when running locally without an SSL-terminating reverse proxy.
#
# Root cause (hyrax-webapp config/initializers/hyrax.rb):
#
#   Both iiif_image_url_builder and iiif_info_url_builder unconditionally
#   rewrite base_url from http: → https:
#
#     base_url = base_url.sub(/\Ahttp:/, 'https:')
#
#   On the production VM this is correct — Nginx terminates SSL and the app
#   is behind a proxy, so IIIF URLs must be https:// to avoid mixed-content
#   errors in the browser.
#
#   Locally (docker-compose.local.yml) there is no SSL termination; the app
#   serves plain HTTP. The rewrite produces https:// IIIF URLs that the browser
#   cannot reach → ERR_CONNECTION_REFUSED → UV renders broken/empty viewer.
#
# Fix:
#   When DISABLE_FORCE_SSL=true (set in .env.production for local smoke test),
#   re-register both URL builders omitting the http→https substitution.
#   On the VM (DISABLE_FORCE_SSL unset), hyrax-webapp's original builders are
#   left in place and https:// rewriting continues as before.
#
Rails.application.config.after_initialize do
  next unless ENV['DISABLE_FORCE_SSL'].to_s == 'true'

  Hyrax.config.iiif_image_url_builder = lambda do |file_id, base_url, size, _format|
    Riiif::Engine.routes.url_helpers.image_url(file_id, host: base_url, size:)
  end

  Hyrax.config.iiif_info_url_builder = lambda do |file_id, base_url|
    uri = Riiif::Engine.routes.url_helpers.info_url(file_id, host: base_url)
    uri.sub(%r{/info\.json\Z}, '')
  end
end
