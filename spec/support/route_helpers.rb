module RouteHelpers
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::UrlHelper
  end
end

RSpec.configure do |config|
  config.include RouteHelpers, type: :integration
end
