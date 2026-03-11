# frozen_string_literal: true

# Fix: Bulkrax::ImporterJob crashes with Zip::Error when the uploaded import
# file is corrupt, truncated, or has a .zip extension but is not a valid zip.
#
# Root cause (bulkrax 9.3.5):
#
#   ImporterJob#perform calls unzip_imported_file unconditionally whenever
#   parser.file? && parser.zip? is truthy.  If rubyzip cannot parse the
#   central directory (e.g. the file was only partially uploaded, or the
#   user picked the wrong file), Zip::Error bubbles up uncaught.
#
#   ImporterJob already rescues CSV::MalformedCSVError and calls
#   importer.set_status_info(e) to surface it in the Bulkrax UI.
#   Zip::Error was simply omitted from that rescue clause.
#
# Fix:
#   Prepend a module that mirrors the existing CSV rescue pattern and
#   also catches Zip::Error, marking the importer failed with a human-
#   readable message rather than silently crashing the GoodJob worker.
#
module WvuKnapsack
  module BulkraxImporterJobZipFix
    def perform(importer_id, only_updates_since_last_import = false)
      super
    rescue Zip::Error => e
      importer = Bulkrax::Importer.find_by(id: importer_id)
      if importer
        importer.set_status_info(e)
      else
        Rails.logger.error "[BulkraxZipFix] Zip::Error on importer #{importer_id}: #{e.message}"
      end
    end
  end
end

Rails.application.config.after_initialize do
  Bulkrax::ImporterJob.prepend(WvuKnapsack::BulkraxImporterJobZipFix)
end
