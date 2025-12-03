# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource Document --flexible`
class DocumentForm < Hyrax::Forms::ResourceForm(Document)
  check_if_flexible(Document)
  include VideoEmbedBehavior::Validation
end
