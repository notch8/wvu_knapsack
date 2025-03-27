# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource Congressional --flexible`
class Congressional < Hyrax::Work
  
  include Hyrax::ArResource
  include Hyrax::NestedWorks
  
  include IiifPrint.model_configuration(
    pdf_split_child_model: GenericWorkResource,
    pdf_splitter_service: IiifPrint::TenantConfig::PdfSplitter
  )
  
end 