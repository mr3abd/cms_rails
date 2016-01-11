module Cms
  module Caching
    module ClassMethods
      def cacheable opts = {}
        self.class_variable_set :@@cacheable, true
        opts[:expires_on] ||= nil

        self.after_update :expire
      end

      def cacheable?
        if !self.class_variable_defined?(:@@cacheable)
          return false
        end
        self.class_variable_get :@@cacheable || false
      end
    end

    module InstanceMethods
      def cacheable?
        self.class.cacheable?
      end

      def cached?

      end

      def expired?
        !cached?
      end

      def expire

      end
    end
  end
end