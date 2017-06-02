module Cms
  module Helpers
    module TagsHelper
      def self.included(base)
        methods = [:h1_text]
        if base.respond_to?(:helper_method)
          base.helper_method methods
        end
      end

      def h1_text(key_or_instance = nil)
        instance = key_or_instance || @page_instance
        if instance.is_a?(String) || instance.is_a?(Symbol)
          instance = Pages.send(instance)
        end

        instance.try(:h1_text)
      end
    end
  end
end