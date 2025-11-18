# frozen_string_literal: true

CatalogController.configure_blacklight do |config|
  config.advanced_search[:form_facet_partial] = "advanced_search_facets"
end
