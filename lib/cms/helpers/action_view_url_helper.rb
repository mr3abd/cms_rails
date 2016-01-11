module Cms
  module Helpers
    module ActionView
      module UrlHelper
        def self.included(base)
          methods = self.instance_methods
          methods.delete(:included)
          if base.respond_to?(:helper_method)
            base.helper_method methods
          end

        end

        def link_to_if_with_block condition, options, html_options={}, &block
          if condition
            link_to options, html_options, &block
          else
            #capture &block
          end
        end
      end
    end
  end
end