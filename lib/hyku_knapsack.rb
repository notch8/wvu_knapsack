# frozen_string_literal: true
require "hyku_knapsack/version"
require "hyku_knapsack/engine"

# Explicitly disable include_metadata for flexible mode to prevent loading core_metadata schema
# This must be set very early, before models are loaded (which can happen during engine initialization)
ENV['HYRAX_DISABLE_INCLUDE_METADATA'] = 'true' if ENV.fetch('HYRAX_FLEXIBLE', 'true') != 'false'

module HykuKnapsack
  # Your code goes here...
end
