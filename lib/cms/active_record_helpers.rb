module Cms
  module ActiveRecordHelpers
    def has_url
      safe_include(self, Cms::PageUrlHelpers)
    end

    def has_cache(has_url_module = true, &block)
      added = false
      if !self.respond_to?(:cacheable?) || !self.cacheable?
        has_url if has_url_module

        safe_extend(self, Cms::Caching::ClassMethods)
        safe_include self, Cms::Caching::InstanceMethods

        safe_extend(self, Cms::Helpers::CacheNamingHelper)
        safe_include(self, Cms::Helpers::CacheNamingHelper)

        self.send :cacheable



        added = true
      end

      if block_given?
        self.class_variable_set(:@@_cache_method, block)
      end

      return added
    end
  end
end

ActiveRecord::Base.send :extend, Cms::ActiveRecordHelpers