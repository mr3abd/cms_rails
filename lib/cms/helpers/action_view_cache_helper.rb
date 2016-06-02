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

        def cache_with_url key, &block
          name = cache_fragment_name_with_url(key)
          cache name, &block
        end

        def cache_with_locale key, &block
          name = cache_fragment_name_with_locale(key)
          cache name, &block
        end
      end
    end
  end
end