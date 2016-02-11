require "cms/version"
require 'cms/config'
require 'cms/object_extensions'
require 'cms/active_record_extensions'
#require 'cms/page'
require 'cms/pages'
#require 'cms/meta_tags'
#require 'cms/sitemap_record'
#require 'cms/html_block'
#require 'cms/keyed_html_block'
#require 'cms/banner'
#require 'cms/form_config'

require 'cms/helpers/pages_helper'
require 'cms/helpers/meta_data_helper'
require 'cms/helpers/navigation_helper'
require 'cms/helpers/action_view_url_helper'
require 'cms/helpers/image_helper'

require 'cms/app_router'
require 'cms/page_url_helpers'
require 'cms/resource_navigation'
require 'cms/caching'


require "cms/active_record_helpers"

require 'cms/articles/activerecord_extensions'

require "cms/engine"


module Cms
  # Your code goes here...
end

include_caching_to_models = true
# if include_caching_to_models
#   c = ActiveRecord::Base
#   c.send :include, Cms::PageUrlHelpers
#   c.send :extend, Cms::Caching::ClassMethods
#   c.send :include, Cms::Caching::InstanceMethods
# end

