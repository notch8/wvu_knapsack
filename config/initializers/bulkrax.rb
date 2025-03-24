# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Rails.application.config.after_initialize do
  Bulkrax.setup do |config|
    # Add or remove local parsers
    # Keep only CSV parser
    config.parsers = [
      { name: "CSV - Comma Separated Values", class_name: "Bulkrax::CsvParser", partial: "csv_fields" }
    ]

    # WorkType to use as the default if none is specified in the import
    # Default is the first returned by Hyrax.config.curation_concerns, stringified
    # config.default_work_type = "GenericWorkResource"
  end
end
# rubocop:enable Metrics/BlockLength
