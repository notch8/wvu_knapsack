# frozen_string_literal: true

# Use this to override any Hyrax configuration from the Knapsack

Rails.application.config.after_initialize do
  Hyrax.config do |config|
  # Injected via `rails g hyrax:work_resource BornDigital`
  config.register_curation_concern :born_digital
  # Injected via `rails g hyrax:work_resource Congressional`
  config.register_curation_concern :congressional
  # Injected via `rails g hyrax:work_resource FolkMusic`
  config.register_curation_concern :folk_music
  # Injected via `rails g hyrax:work_resource Medicine`
  config.register_curation_concern :medicine
  # Injected via `rails g hyrax:work_resource OralHistory`
  config.register_curation_concern :oral_history
  end
end
