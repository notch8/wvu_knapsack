# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource Document --flexible`
class DocumentIndexer < Hyrax::ValkyrieWorkIndexer
  include Hyrax::Indexer('Document')
  include HykuIndexing
  check_if_flexible(Document)
end
