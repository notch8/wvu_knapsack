# frozen_string_literal: true

# OVERRIDE Hyku to delegate additional properties
Hyku::WorkShowPresenter.delegate :format, to: :solr_document
