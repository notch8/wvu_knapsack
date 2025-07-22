# frozen_string_literal: true

require 'sentry-ruby'
require 'sentry-sidekiq'

Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.environment = ENV['SENTRY_ENVIRONMENT']
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.enabled_environments = %w[wvu-knapsack-staging wvu-knapsack-production]
  config.debug = true
end
