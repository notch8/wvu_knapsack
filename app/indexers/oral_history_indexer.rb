# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource OralHistory --flexible`
class OralHistoryIndexer < Hyrax::ValkyrieWorkIndexer
  include HykuIndexing
  # check_if_flexible adds Hyrax::Indexer with M3SchemaLoader for flexible models
  check_if_flexible(OralHistory)
end
