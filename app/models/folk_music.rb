# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource FolkMusic --flexible`
class FolkMusic < Hyrax::Work
  include Hyrax::ArResource
  include Hyrax::NestedWorks

  include IiifPrint.model_configuration(
    pdf_split_child_model: self,
    pdf_splitter_service: IiifPrint::TenantConfig::PdfSplitter
  )
end
