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
          entry = { loc: url, changefreq: e.change_freq, priority: e.priority.to_f}
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

    def self.entries_for_resources(resources = nil, locales = nil)
      if resources.nil?
        resources = registered_resource_classes.map do |klass|
          klass.try(:published) || klass.try(:all)
        end
      end

      if locales && (locales.is_a?(Symbol) || locales.is_a?(String))
        locales = [locales]
      end
      locales ||= Cms.config.provided_locales

      local_entries = []
      urls = []
      flatten_resources = resources.flatten.select{|r| !r.nil? }
      flatten_resources.map do |e|
        locales.each do |locale|
          url = url(e, locale)
          if urls.include?(url)
            next
          end

          default_change_freq = Cms.config.default_sitemap_change_freq
          default_priority = Cms.config.default_sitemap_priority

          changefreq = e.sitemap_record.try(:changefreq)
          if changefreq.blank? || changefreq.to_sym == :default
            changefreq = e.try(:change_freq) || e.class.try(:default_change_freq) || default_change_freq
          end

          priority = e.sitemap_record.try(:priority)
          if priority.blank?
            (e.try(:priority) || e.class.try(:default_priority) || default_priority)
          end

          priority = priority.to_f


          urls << url
          entry = { loc: url,
                    changefreq: changefreq,
                    priority: priority}
          lastmod = e.try(:updated_at)
          lastmod = nil if lastmod.blank?
          local_lastmod = lastmod
          if local_lastmod
            entry[:lastmod] = local_lastmod.to_datetime.strftime if local_lastmod.present?
          end
          local_entries << entry
        end
      end

      local_entries
    end

    def self.url(page, locale = I18n.locale )
      host = (ENV["#{Rails.env}.host_with_port"] || ENV["#{Rails.env}.host"]) || Rails.application.config.action_mailer.default_url_options.try{|opts| "http://#{opts[:host]}" }
      if p = page
        s = p.url(locale)
        s = p.default_url(locale) if s.blank?
        v = "#{host}#{s}"
        return v
      end


      nil
    end

    def url(locale = I18n.locale, page = self.page)
      self.class.url(page, locale)
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