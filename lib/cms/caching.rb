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

    def self.cacheable_models
      Cms::Caching.class_variable_get(:@@cacheable_models) rescue [] || []
    end

    def self.clear_cache
      Cms::Caching.cacheable_models.each{|m| m.all.each(&:clear_cache) }
    end



    module ClassMethods


      def cacheable opts = {}
        self.class_variable_set :@@cacheable, true
        opts[:expires_on] ||= nil
        models = Cms::Caching.cacheable_models
        models << self if !models.include?(self)
        Cms::Caching.class_variable_set(:@@cacheable_models, models)



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

      def cache_instances(&block)
        if block_given?
          class_variable_set(:@@_cache_instances_method, block)
        else
          (class_variable_get(:@@_cache_instances_method) rescue nil) || nil
        end
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

      def calculate_expired_paths(include_dependencies = true, filter_existing = true, **options)
        options[:format] ||= [:html, :json]
        options[:allow_format] ||= [:xml]
        options[:ignore_gzip] ||= false
        expired_pages = []
        expired_fragments = []
        if !include_dependencies
          paths = self.cache_path
          paths.each do |path|
            expired_pages << path
          end
          return
        end


        cache_method = (self.class.class_variable_get(:@@_cache_method) rescue nil) || nil
        if cache_method
          Cms.with_locales do
            instance_eval(&cache_method)
          end

          expired_pages = pages
          fragments = self.fragments
        else
          instances = cache_instances
          expired_pages = paths_for_instances(instances)
          fragments = cache_fragments
          fragments = fragments.flatten if fragments.respond_to?(:flatten)
          fragments = [fragments] if !fragments.respond_to?(:each)
        end





        if fragments.present?
          fragments.each do |fragment_key|
            expired_fragments << fragment_key
          end
        end

        expired_pages = expired_pages.select(&:present?).uniq
        if filter_existing
          public_path = Rails.root.join("public").to_s
          public_path = public_path[0, public_path.length - 1] if public_path.end_with?("/")
          
          expired_pages = expired_pages.map{|p|
            relative_path = p
            relative_path = "/#{p}" if !relative_path.start_with?("/")
            path = "#{public_path}#{relative_path}"

            gzipped_path = "#{path}.gz"
            gzipped_files = Dir[gzipped_path]

            (Dir[path] + gzipped_files).uniq
          }.flatten.map{|s| s.gsub(/\A#{public_path}/, "") }
        end

        filtered_file_names = filter_file_name(expired_pages, options)
        if filtered_file_names
          expired_pages = filtered_file_names
        end

        expired_fragments = expired_fragments.flatten.select(&:present?).uniq
        if filter_existing
          expired_fragments = expired_fragments.select{|f| _get_action_controller.fragment_exist?(f) rescue true  }
        end


        {pages: expired_pages, fragments: expired_fragments}
      end

      def symbols_to_page_instances(keys)
        if keys.is_a?(Symbol)
          if keys == :all
            return keys
          else
            return Pages.send(keys)
          end

        elsif keys.respond_to?(:map)
          keys.map{ |k|
            next symbols_to_page_instances(k)
          }.flatten
        else
          return keys
        end
      end

      def paths_for_instances(instances, locales = I18n.locale)
        instances = [instances] unless instances.respond_to?(:each)
        instances = instances.uniq.select(&:present?)
        instances = symbols_to_page_instances(instances)
        locales = [locales] if !locales.is_a?(Array)
        expired_pages = []

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
                  break
                end

                if child == :all
                  expired_pages += Cms::Caching.cacheable_models.map{|m|m.all.map{|p| p.cache_path(nil, locales) rescue nil }.select(&:present?)}.flatten
                  next
                end

                if child.is_a?(Class) && child.parent_classes.include?(ActiveRecord::Base)
                  expired_pages += child.all.map{|p| p.cache_path(nil, locales) rescue nil }.select(&:present?)
                  next
                end

                if child.is_a?(Symbol)
                  child = Pages.send(child)
                end

                begin
                  paths = child.cache_path(nil, locales)
                rescue
                  next
                end

                if paths.nil?
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
              elsif instance.is_a?(Symbol)
                if instance == :all
                  expired_pages += Cms::Caching.cacheable_models.map{|m|m.all.map{|p| p.cache_path(nil, locales) rescue nil }.select(&:present?)}.flatten
                  next
                end

                begin
                  expired_pages << Pages.send(instance).cache_path(nil, locales)
                  next
                rescue
                  next
                end

              end

              begin
                paths = instance.cache_path(nil, locales)
              rescue
                next
              end

              if paths.nil?
                next
              end

              paths.each do |path|
                expired_pages << path
              end
            end
          end
        end

        expired_pages.uniq
      end

      def pages(*keys, **options, &block)
        cache_pages = instance_variable_get(:@_cache_pages) rescue nil
        if keys.count == 0 && !block_given? && !cache_pages.nil?
          return cache_pages
        end

        locales = options[:locales] || Cms.locales

        cache_pages = [] if cache_pages.nil?

        cache_pages << paths_for_instances(keys, locales)
        cache_pages = cache_pages.uniq.flatten
        instance_variable_set(:@_cache_pages, cache_pages)

        cache_pages
      end

      def fragments(keys = nil, locales = nil, &block)
        cache_fragments = instance_variable_get(:@_cache_fragments) rescue nil
        if keys.nil? && !block_given? && !cache_fragments.nil?
          return cache_fragments
        end

        cache_fragments = [] if cache_fragments.nil?

        locales = Cms.locales if locales.blank?
        cache_fragments << locales.map{|locale| next "#{locale}_#{keys}" if keys.is_a?(String) || keys.is_a?(Symbol); keys.map{|k| "#{locale}_#{k}" } }.flatten
        cache_fragments = cache_fragments.uniq
        instance_variable_set(:@_cache_fragments, cache_fragments)

        cache_fragments
      end

      def filter_file_name(pages, options = {})
        if options[:ignore_gzip] || options[:format] || options[:allow_format]
          gzipped_files = []
          expired_pages = pages.select{|f|
            if options[:ignore_gzip] && f.end_with?(".gz")
              next false
            else
              if options[:format]
                formats = options[:format] + options[:allow_format]
                if !formats.is_a?(Array)
                  format = formats
                  next f.end_with?(".#{format}")
                else
                  next formats.any?{|format| f.to_s.end_with?(format.to_s) }
                end
              end
            end
          }

          return expired_pages
        else
          return false
        end


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
        @_url_helpers ||= Rails.application.routes.url_helpers
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

      def has_format?(url = nil)
        url ||= self.url
        Rails.application.routes.recognize_path(url)[:format].present?
      end

      def cache_path(url = nil, locales = I18n.locale, formats = [:html, :json])
        if locales.respond_to?(:count)
          paths = locales.map{|locale| cache_path(url, locale, formats) }.flatten
          if paths.count > 1
            return paths
          else
            return paths.first
          end

        end

        url ||= self.url(locales)
        if !url
          return []
        end
        path = url

        paths = []

        if url == "/" || url == ""
          formats.each do |format|
            paths << "index.#{format}"
          end
        elsif !has_format?(url)
          formats.each do |format|
             paths << path + ".#{format}"
          end
        else
          paths << path
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
