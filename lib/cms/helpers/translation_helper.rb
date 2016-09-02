module Cms
  module Helpers
    module TranslationHelper
      def self.included(base)
        methods = self.instance_methods
        methods.delete(:included)
        if base.respond_to?(:helper_method)
          base.helper_method methods
        end

      end

      def t(*args)
        Cms.t(*args)
      end
    end
  end
end
