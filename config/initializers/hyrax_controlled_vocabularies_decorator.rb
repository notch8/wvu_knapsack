# frozen_string_literal: true

# OVERRIDE Hyku 6.2.0.rc3 to add custom local authorities

module Hyrax
  module ControlledVocabulariesDecorator
    extend ActiveSupport::Concern
    class_methods do
      def services
        super.merge(
          {
            'congress' => 'Hyrax::CongressService'
          }
        )
      end
    end
  end
end

Hyrax::ControlledVocabularies.prepend(Hyrax::ControlledVocabulariesDecorator)
