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
      locales ||= Cms.config.provided_locales

      local_entries = []
      urls = []
      Cms::SitemapElement.where(display_on_sitemap: "t").map do |e|
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
      end.select do|e|
        if page.respond_to?(:published?)
          next page.published?
        else
          next true
        end
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
  end
end