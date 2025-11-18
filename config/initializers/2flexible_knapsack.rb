# frozen_string_literal: true

# Add knapsack-specific work types to HYRAX_FLEXIBLE_CLASSES
# This runs after the submodule's 1flexible.rb initializer to append our custom classes

flexible = ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYRAX_FLEXIBLE', 'true'))
if flexible
  # Get existing classes from ENV (set by submodule's 1flexible.rb)
  existing_classes = ENV.fetch('HYRAX_FLEXIBLE_CLASSES', '').split(',').map(&:strip).reject(&:empty?)
  
  # Add knapsack-specific work types
  knapsack_classes = %w[
    Document
    BornDigital
    Congressional
    FolkMusic
    Medicine
    OralHistory
  ]
  
  # Combine and set back to ENV
  all_classes = (existing_classes + knapsack_classes).uniq
  ENV['HYRAX_FLEXIBLE_CLASSES'] = all_classes.join(',')
end

