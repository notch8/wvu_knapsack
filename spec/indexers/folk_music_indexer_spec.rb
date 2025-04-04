# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource FolkMusic`
require 'rails_helper'
require 'hyrax/specs/shared_specs/indexers'

RSpec.describe FolkMusicIndexer do
  let(:indexer_class) { described_class }
  let!(:resource) { Hyrax.persister.save(resource: FolkMusic.new) }

  it_behaves_like 'a Hyrax::Resource indexer'
end
