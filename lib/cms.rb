require "cms/engine"
require "cms/version"
require 'cms/config'
require 'cms/object_extensions'
require 'cms/utils'
require 'cms/active_record_extensions'
#require 'cms/page'
require 'cms/pages'
require 'cms/json_data'
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

require 'cms/articles/activerecord_migrations'
require 'cms/articles/activerecord_helpers'

require 'cms/banners/activerecord_helpers'
require 'cms/banners/activerecord_migrations'
require 'cms/banners/owner_methods'

require 'cms/content_blocks/activerecord_helpers'
require 'cms/content_blocks/activerecord_migrations'
require 'cms/banners/owner_methods'



require 'rails_admin_extensions/config'



module Cms
  class << self
    def pages_models
      Dir[Rails.root.join("app/models/pages/*")].map{|p| filename = File.basename(p, ".rb"); "Pages::" + filename.camelize }
    end

    def templates_models
      Dir[Rails.root.join("app/models/templates/*")].map{|p| filename = File.basename(p, ".rb"); "Templates::" + filename.camelize }
    end

    def config(&block)
      config_class = Cms::Config
      if block_given?
        config_class.instance_eval(&block)
      end

      return config_class
    end

    def configure_rails_admin(config)
      models = [Cms::MetaTags]
      config.include_pages_models
      config.include_models(*models)

      models.each do |m|

        m.configure_rails_admin(config)
      end

      if Cms.config.use_translations && Cms::Page.respond_to?(:translation_class)
        config.model Cms::Page.translation_class do
          visible false
        end
      end
    end


  end
end

include_caching_to_models = true
# if include_caching_to_models
#   c = ActiveRecord::Base
#   c.send :include, Cms::PageUrlHelpers
#   c.send :extend, Cms::Caching::ClassMethods
#   c.send :include, Cms::Caching::InstanceMethods
# end

