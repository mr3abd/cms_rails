module Cms
  module Helpers
    module CacheNamingHelper
      def self.included(base)
        methods = self.instance_methods
        methods.delete(:included)
        if base.respond_to?(:helper_method)
          base.helper_method methods
        end
      end

      def cache_fragment_name_with_url(key, locale = I18n.locale)
        if self.is_a?(ActiveRecord::Base)
          targets = [self, @page_instance]
        else
          targets = [@page_instance, self]
        end

        res = nil
        targets.each do |target|
          r = target.try{|p| ( (p.respond_to?(:url) ? p.url(locale) : nil) || "")  }
          if r.present?
            res = r + "/"
            break
          end
        end
        "#{res}#{key}"
      end

      def cache_fragment_name_with_locale(key, locale = I18n.locale)
        "#{locale}_#{key}"
      end

      def cache_fragment_names_with_locales(key)
        Cms.config.provided_locales.map do |locale|
          cache_fragment_name_with_locale(key, locale)
        end
      end

      def cache_fragment_names_with_urls(key)
        Cms.config.provided_locales.map do |locale|
          cache_fragment_name_with_locale(key, locale)
        end
      end
    end
  end
end