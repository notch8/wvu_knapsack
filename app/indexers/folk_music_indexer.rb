# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource FolkMusic --flexible`
class FolkMusicIndexer < Hyrax::ValkyrieWorkIndexer
  include Hyrax::Indexer('FolkMusic')
  include HykuIndexing
end
