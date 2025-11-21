# frozen_string_literal: true

# OVERRIDE Blacklight Advanced Search v7.0.0 to prevent double rendering of constraint filters

module BlacklightAdvancedSearch
  module RenderConstraintsOverrideDecorator
    def render_constraints_filters(params_or_search_state = search_state)
      original_blacklight_method = Blacklight::RenderConstraintsHelperBehavior.instance_method(__method__)
      original_blacklight_method.bind(self).call(params_or_search_state)
    end
  end
end

BlacklightAdvancedSearch::RenderConstraintsOverride.prepend(BlacklightAdvancedSearch::RenderConstraintsOverrideDecorator)
