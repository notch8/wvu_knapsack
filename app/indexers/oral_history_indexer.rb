# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource OralHistory --flexible`
class OralHistoryIndexer < Hyrax::ValkyrieWorkIndexer
  include Hyrax::Indexer('OralHistory')
  include HykuIndexing
end
