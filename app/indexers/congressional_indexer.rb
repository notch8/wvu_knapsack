# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource Congressional --flexible`
class CongressionalIndexer < Hyrax::ValkyrieWorkIndexer
  include Hyrax::Indexer('Congressional')
  include HykuIndexing
end
