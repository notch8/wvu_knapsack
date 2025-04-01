# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource OralHistory --flexible`
class OralHistory < Hyrax::Work
  include Hyrax::ArResource
  include Hyrax::NestedWorks

  include IiifPrint.model_configuration(
    pdf_split_child_model: GenericWorkResource,
    pdf_splitter_service: IiifPrint::TenantConfig::PdfSplitter
  )
end
