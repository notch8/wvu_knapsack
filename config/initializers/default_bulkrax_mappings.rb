# frozen_string_literal: true

# This lambda is used to set the default field mapping for Bulkrax:
# conf.default_field_mapping = lambda do |field|
#   return if field.blank?
#   {
#     field.to_s =>
#     {
#       from: [field.to_s],
#       split: false,
#       parsed: Bulkrax::ApplicationMatcher.method_defined?("parse_#{field}"),
#       if: nil,
#       excluded: false
#     }
#   }
# end

## Set custom bulkrax parser field mappings for app if not using above
# parser_mappings = {

# }

# # all parsers use the same mappings:
# mappings = {}
# mappings["Bulkrax::CsvParser"] = parser_mappings
# Hyku.default_bulkrax_field_mappings = mappings
