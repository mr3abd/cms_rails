module Cms
  class BaseController < ::ApplicationController
    safe_include ActionView::Helpers::OutputSafetyHelper
    safe_include Cms::Helpers::ImageHelper
    safe_include ActionView::Helpers::AssetUrlHelper
    safe_include ActionView::Helpers::TagHelper
    safe_include ActionView::Helpers::UrlHelper
    safe_include Cms::Helpers::UrlHelper
    safe_include Cms::Helpers::PagesHelper
    safe_include Cms::Helpers::MetaDataHelper
    safe_include Cms::Helpers::NavigationHelper
    safe_include Cms::Helpers::ActionView::UrlHelper
    safe_include Cms::Helpers::Breadcrumbs
    safe_include ActionControllerExtensions::InstanceMethods
    safe_include ::ApplicationHelper
    safe_include Cms::Helpers::AnotherFormsHelper
    safe_include Cms::Helpers::TagsHelper
    safe_include Cms::Helpers::AssetHelper
  end
end