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

    def has_cache
      has_url

      safe_extend(self, Cms::Caching::ClassMethods)
      safe_include self, Cms::Caching::InstanceMethods

      self.send :cacheable
    end
  end
end

ActiveRecord::Base.send :extend, Cms::ActiveRecordHelpers