# frozen_string_literal: true

# Generated via
#  `rails generate hyku_knapsack:work_resource Document --flexible`
class Document < Hyrax::Work
  include Hyrax::ArResource
  include Hyrax::NestedWorks
  include Hyrax::Flexibility if Hyrax.config.flexible?

  include IiifPrint.model_configuration(
    pdf_split_child_model: self,
    pdf_splitter_service: IiifPrint::TenantConfig::PdfSplitter
  )
end
