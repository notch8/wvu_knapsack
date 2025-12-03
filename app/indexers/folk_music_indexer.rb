# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource FolkMusic --flexible`
class FolkMusicIndexer < Hyrax::ValkyrieWorkIndexer
  include HykuIndexing
  # check_if_flexible adds Hyrax::Indexer with M3SchemaLoader for flexible models
  check_if_flexible(FolkMusic)
end
