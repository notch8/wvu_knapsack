# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource OralHistory --flexible`
class OralHistoryForm < Hyrax::Forms::ResourceForm(OralHistory)
  check_if_flexible(OralHistory)
  include VideoEmbedBehavior::Validation
end
