# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource Congressional --flexible`
class CongressionalForm < Hyrax::Forms::ResourceForm(Congressional)
  check_if_flexible(Congressional)
  include VideoEmbedBehavior::Validation
end
