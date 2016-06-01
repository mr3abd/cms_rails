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
          name = "#{I18n.locale}_#{key}"
          cache(name, options, &block)

          nil
        end
      end
    end
  end
end