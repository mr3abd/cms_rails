module Cms
  module Helpers
    module ActionView
      module CacheHelper
        def self.included(base)
          methods = self.instance_methods
          methods.delete(:included)
          if base.respond_to?(:helper_method)
            base.helper_method methods
          end

        end

        def cache_with_locale key, options = {}, &block
          key = "#{I18n.locale}_#{key}"
          cache key, options, &block
        end
      end
    end
  end
end