# frozen_string_literal: true
# Be sure to restart your server when you modify this file.

# Prepend knapsack assets directory to ensure overrides take precedence
# This allows files in app/assets to override files in hyrax-webapp/app/assets
Rails.application.config.assets.paths.unshift(
  Rails.root.join('app', 'assets', 'javascripts').to_s,
  Rails.root.join('app', 'assets', 'stylesheets').to_s,
  Rails.root.join('app', 'assets', 'images').to_s
)

