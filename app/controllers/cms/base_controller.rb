require 'cms/helpers'

module Cms
  class BaseController < ::ApplicationController
    safe_include self, ActionView::Helpers::OutputSafetyHelper
    safe_include self, Cms::Helpers::ImageHelper
    safe_include self, ActionView::Helpers::AssetUrlHelper
    safe_include self, ActionView::Helpers::TagHelper
    safe_include self, ActionView::Helpers::UrlHelper
    safe_include self, Cms::Helpers::UrlHelper
    safe_include self, Cms::Helpers::PagesHelper
    safe_include self, Cms::Helpers::MetaDataHelper
    safe_include self, Cms::Helpers::NavigationHelper
    safe_include self, Cms::Helpers::ActionView::UrlHelper
    safe_include self, Cms::Helpers::Breadcrumbs
    safe_include self, ActionControllerExtensions::InstanceMethods
    safe_include self, ::ApplicationHelper
    safe_include self, Cms::Helpers::AnotherFormsHelper
    safe_include self, Cms::Helpers::TagsHelper
    safe_include self, Cms::Helpers::AssetHelper
  end
end