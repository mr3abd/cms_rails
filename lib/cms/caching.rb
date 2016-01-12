module Cms
  module Caching
    module ClassMethods
      def cacheable opts = {}
        self.class_variable_set :@@cacheable, true
        opts[:expires_on] ||= nil

        self.after_update :expire
        self.after_destroy :expire
      end

      def cacheable?
        if !self.class_variable_defined?(:@@cacheable)
          return false
        end
        self.class_variable_get :@@cacheable || false
      end

      def self.depends_on(*keys, **options)

      end
    end

    module InstanceMethods
      def cacheable?
        self.class.cacheable?
      end

      def cached?
        File.exists?(self.full_cache_path)
      end

      def expired?
        !cached?
      end

      def expire
        _get_action_controller.expire_page(self.cache_path)
      end

      def url_helpers
        @_url_helpers = Rails.application.routes.url_helpers
      end

      def _get_action_controller
        @_action_controller ||= ActionController::Base.new
      end

      def expire_fragment key, options = nil
        _get_action_controller.expire_fragment(key, options)
      end

      def expire_page options = {}
        _get_action_controller.expire_page(options)
      end

      def has_format?
        Rails.application.routes.recognize_path(url)[:format].present?
      end

      def cache_path(url = nil)
        url ||= self.url
        path = url

        if url == "/" || url == ""
          path = "index.html"
        elsif !has_format?
          path += ".html"
        end


        path
      end

      def full_cache_path(url = nil)
        path = cache_path(url)
        cache_dir = Rails.application.root.join("public")
        "#{cache_dir}#{path}"
      end
    end
  end
end