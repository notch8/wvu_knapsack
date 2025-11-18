# frozen_string_literal: true

# Use this to override any Hyrax configuration from the Knapsack

Rails.application.config.after_initialize do
  Hyrax.config do |config|
    config.flexible = true # ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYRAX_FLEXIBLE', false))

    # Set default profile path
    config.schema_loader_config_search_paths = HykuKnapsack::Engine.root.join('config', 'metadata_profiles', 'm3_profile.yaml')
    # Clears the default registered concerns and adds in the concerns specified in the m3_profile.yaml
    config.instance_variable_set(:@registered_concerns, [])
    # Injected via `rails g hyku_knapsack:work_resource Document --flexible`
    config.register_curation_concern :document
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
  end

  # Ensure that only the registered concerns can be nested within each other
  # Hyrax::NestedWorks loads the valid_child_concerns prior to the above configuration
  # This removes Hyku's default work types from the list of valid child concerns
  Hyrax.config.curation_concerns.each do |concern|
    concern.valid_child_concerns = Hyrax.config.curation_concerns
  end
end
