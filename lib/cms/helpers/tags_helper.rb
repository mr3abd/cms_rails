module Cms
  module Helpers
    module TagsHelper
      def h1_text(key_or_instance = nil)
        instance = key_or_instance || @page_instance
        if instance.is_a?(String) || instance.is_a?(Symbol)

          instance = Pages.send(instance)
        end
      end
    end
  end
end