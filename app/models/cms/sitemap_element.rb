module Cms
  class SitemapElement < ActiveRecord::Base
    self.table_name = :sitemap_elements
    extend Enumerize

    attr_accessible *attribute_names

    belongs_to :page, polymorphic: true

    attr_accessible :page

    enumerize :changefreq, in: [:default, :always, :hourly, :daily, :weekly, :monthly, :yearly, :never], default: :default

    before_save :set_defaults



    def set_defaults
      default_priority = 0.5
      self.priority = default_priority if priority.blank?
      #self.display_on_sitemap ||= true
    end

    def self.entries(locales = nil)
      if locales && (locales.is_a?(Symbol) || locales.is_a?(String))
        locales = [locales]
      end
      locales ||= Cms.config.provided_locales

      local_entries = []
      urls = []
      Cms::SitemapElement.where(display_on_sitemap: "t").to_a.select do|e|
        if e.page.respond_to?(:published?)
          next e.page.published?
        else
          next true
        end
      end.map do |e|
        locales.each do |locale|
          url = e.url(locale)
          if urls.include?(url)
            next
          end
          urls << url
          entry = { loc: url, changefreq: e.change_freq, priority: e.priority}
          local_lastmod = e.lastmod(locale)
          if local_lastmod
            entry[:lastmod] = local_lastmod.to_datetime.strftime if local_lastmod.present?
          end
          local_entries << entry
        end

        e
      end

      local_entries
    end

    def url(locale = I18n.locale)
      host = Rails.application.config.action_mailer.default_url_options.try{|opts| "http://#{opts[:host]}" }
      if p = page
        s = p.url(locale)
        s = p.default_url(locale) if s.blank?
        v = "#{host}#{s}"
        return v
      end


      nil
    end

    def lastmod locale = I18n.locale
      v = page.try(:updated_at)
      if v.blank?
        return nil
      else
        return v
      end
    end

    def change_freq
      if changefreq == :default
        return :monthly
      end

      return changefreq
    end

    def self.register_resource_class(klass)
      var_name = :@@_resource_classes
      resource_classes = self.class_variable_get(var_name) || [] rescue []
      resource_classes << klass unless resource_classes.include?(klass)
      self.class_variable_set(var_name, resource_classes)
    end

    def self.registered_resource_classes
      var_name = :@@_resource_classes
      self.class_variable_get(var_name) || [] rescue []
    end

    def self.registered_resource_class?(klass)
      registered_resource_classes.include?(klass)
    end
  end
end