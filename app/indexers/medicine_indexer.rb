# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource Medicine --flexible`
class MedicineIndexer < Hyrax::ValkyrieWorkIndexer
  include Hyrax::Indexer('Medicine')
  include HykuIndexing
  check_if_flexible(Medicine)
end
