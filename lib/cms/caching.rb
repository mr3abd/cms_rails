module Cms
  module Caching
    def self.cached_instances( instances )
      if !instances.is_a?(Array)
        instances = [instances]
      end
      instances.map do |item|
        if item.is_a?(ActiveRecord::Relation)
          next item.to_a
        else
          next item
        end
      end.flatten.select{|page|page.cached? || false}
    end

    module ClassMethods


      def cacheable opts = {}
        self.class_variable_set :@@cacheable, true
        opts[:expires_on] ||= nil


        self.after_create :expire
        self.after_update :expire
        self.after_destroy :expire


      end

      def cacheable_resource opts = {}
        opts[:pages] ||= [:home]
        opts[:pages] ||= []
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
        self.full_cache_path.each do |s|
          return false if File.exists?(s)
        end

        return true
      end

      def calculate_expired_paths(include_dependencies = true, filter_existing = true)
        expired_pages = []
        expired_fragments = []
        if !include_dependencies
          paths = self.cache_path
          paths.each do |path|
            expired_pages << path
          end
          return
        end

        instances = cache_instances
        instances = [instances] unless instances.respond_to?(:each)
        instances = instances.uniq.select(&:present?)
        if instances.present?
          instances.each do |instance|
            if instance.nil?
              next
            end
            if instance.is_a?(Array) || instance.is_a?(ActiveRecord::Relation)
              items = instance
              items = instance.all if instance.is_a?(ActiveRecord::Relation)
              items.each do |child|
                if child.is_a?(String)
                  expired_pages << child
                  next
                end

                begin
                  paths = child.cache_path
                rescue
                  next
                end
                paths.each do |path|
                  expired_pages << path
                end
              end
            else
              if instance.is_a?(String)
                expired_pages << instance
                next
              end

              begin
                paths = instance.cache_path
              rescue
                next
              end
              paths.each do |path|
                expired_pages << path
              end
            end
          end
        end

        fragments = cache_fragments.flatten
        if fragments.present?
          fragments.each do |fragment_key|
            expired_fragments << fragment_key
          end
        end

        expired_pages = expired_pages.uniq
        if filter_existing
          public_path = Rails.root.join("public").to_s
          public_path = public_path[0, public_path.length - 1] if public_path.end_with?("/")
          
          expired_pages = expired_pages.map{|p|
            relative_path = p
            relative_path = "/#{p}" if !relative_path.start_with?("/")
            path = "#{public_path}#{relative_path}"
            gzipped_path = "#{path}.gz"

            (Dir[path] + Dir[gzipped_path]).uniq
          }.flatten.map{|s| s.gsub(/\A#{public_path}/, "") }
        end

        expired_fragments = expired_fragments.uniq
        if filter_existing
          expired_fragments = expired_fragments.select{|f| _get_action_controller.fragment_exist?(f) rescue true  }
        end


        {pages: expired_pages, fragments: expired_fragments}
      end

      def clear_cache(*args)
        # _get_action_controller.expire_page(self.cache_path)
        # if include_dependencies && cache_dependencies.present?
        #   cache_dependencies.each do |dep|
        #     _get_action_controller.expire_page(dep.cache_path)
        #   end
        # end

        paths = calculate_expired_paths(*args)
        pages = paths[:pages]
        pages.each do |path|
          _get_action_controller.expire_page(path) rescue nil
        end

        fragments = paths[:fragments]
        fragments.each do |fragment_key|
          _get_action_controller.expire_fragment(fragment_key)
        end

      end

      def cache_dependencies
        []
      end

      def cache_instances
        [self]
      end

      def cache_fragments
        []
      end

      def expired_urls

      end

      def expired_instances

      end

      def expired?
        !cached?
      end

      def expire
        clear_cache
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

      def cache_path(url = nil, formats = [:html, :json])
        url ||= self.url
        if !url
          return []
        end
        path = url

        paths = []

        if url == "/" || url == ""
          formats.each do |format|
            paths << "index.#{format}"
          end
        elsif !has_format?
          formats.each do |format|
             paths << path + ".#{format}"
          end
        end


        paths
      end



      def full_cache_path(url = nil)
        path = cache_path(url)
        cache_dir = Rails.application.public_path rescue Rails.public_path

        [path].flatten.map{|s| cache_dir.join(s) }
      end
    end
  end
end
