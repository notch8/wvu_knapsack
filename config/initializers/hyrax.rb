# frozen_string_literal: true

# Use this to override any Hyrax configuration from the Knapsack

Rails.application.config.after_initialize do
  Hyrax.config do |config|
  # Injected via `rails g hyrax:work_resource BornDigital`
  config.register_curation_concern :born_digital
  end
end
