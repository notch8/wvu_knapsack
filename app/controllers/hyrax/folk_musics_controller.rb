# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource FolkMusic`
module Hyrax
  # Generated controller for FolkMusic
  class FolkMusicsController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyku::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::FolkMusic

    # Use a Valkyrie aware form service to generate Valkyrie::ChangeSet style
    # forms.
    self.work_form_service = Hyrax::FormFactory.new
  end
end
