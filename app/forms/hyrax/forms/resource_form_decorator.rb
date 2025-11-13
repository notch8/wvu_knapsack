# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.5 to strip out blank values so they don't get presisted to the database

module Hyrax
  module Forms
    module ResourceFormDecorator
      def validate(params)
        params.transform_values! do |value|
          if value.is_a?(Array)
            value.reject(&:blank?)
          elsif value.is_a?(String) && value.blank?
            nil
          else
            value
          end
        end

        super(params)
      end
    end
  end
end

Hyrax::Forms::ResourceForm.prepend(Hyrax::Forms::ResourceFormDecorator)
