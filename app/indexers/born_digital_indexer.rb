# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource BornDigital --flexible`
class BornDigitalIndexer < Hyrax::ValkyrieWorkIndexer
  include Hyrax::Indexer('BornDigital')
  include HykuIndexing
end
