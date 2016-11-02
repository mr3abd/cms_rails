module Cms
  module ActiveRecordHelpers
    def has_url
      safe_include(self, Cms::PageUrlHelpers)
    end

    def safe_include(target, *modules)
      modules.each do |m|
        if !self.included_modules.include?(m)
          self.send :include, m
        end
      end
    end

    def safe_extend(target, *modules)
      modules.each do |m|
        if !self.extended_modules.include?(m)
          self.send :extend, m
        end
      end
    end

    def has_cache(has_url_module = true)
      if !self.respond_to?(:cacheable?) || !self.cacheable?
        has_url if has_url_module

        safe_extend(self, Cms::Caching::ClassMethods)
        safe_include self, Cms::Caching::InstanceMethods

        safe_extend(self, Cms::Helpers::CacheNamingHelper)
        safe_include(self, Cms::Helpers::CacheNamingHelper)

        self.send :cacheable
      end
    end
  end
end

ActiveRecord::Base.send :extend, Cms::ActiveRecordHelpers