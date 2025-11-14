# frozen_string_literal: true

# OVERRIDE Bulkrax v9.3.1 to handle nil values from hash

module Bulkrax
  module NormalizedJsonDecorator
    extend ActiveSupport::Concern

    class_methods do
      def normalize_keys(hash)
        super(hash&.compact)
      end
    end
  end
end

Bulkrax::NormalizedJson.prepend(Bulkrax::NormalizedJsonDecorator)
