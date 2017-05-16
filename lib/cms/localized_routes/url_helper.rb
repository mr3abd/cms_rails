module Cms
  module LocalizedRoutes
    module UrlHelper
      module ActiveRecordExtension
        def url(locale = I18n.locale)
          url_helpers.send("#{route_name}_#{locale}_path")
        end
      end

      module ResourceUrl
        def url(locale = I18n.locale)
          url_fragment = translations_by_locale[locale].try(:url_fragment)
          resource_key = self.class.name.underscore
          if url_fragment.blank?
            return nil
          end
          url_helpers.send("#{resource_key}_#{locale}_path", id: url_fragment)
        end
      end
    end
  end
end

#Cms::Page.send(:include, LocalizedRoutes::UrlHelper::ActiveRecordExtension)