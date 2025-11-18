# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource Medicine --flexible`
class MedicineForm < Hyrax::Forms::ResourceForm(Medicine)
  check_if_flexible(Medicine)
end
