# frozen_string_literal: true

# Use this to override any Hyrax configuration from the Knapsack

Rails.application.config.after_initialize do
  Hyrax.config do |config|
    # Injected via `rails g hyku_knapsack:work_resource BornDigital --flexible`
    config.register_curation_concern :born_digital
    # Injected via `rails g hyku_knapsack:work_resource Congressional --flexible`
    config.register_curation_concern :congressional
    # Injected via `rails g hyku_knapsack:work_resource FolkMusic --flexible`
    config.register_curation_concern :folk_music
    # Injected via `rails g hyku_knapsack:work_resource Medicine --flexible`
    config.register_curation_concern :medicine
    # Injected via `rails g hyku_knapsack:work_resource OralHistory --flexible`
    config.register_curation_concern :oral_history
    # Injected via `rails g hyku_knapsack:work_resource Document --flexible`
    config.register_curation_concern :document
  end
end
