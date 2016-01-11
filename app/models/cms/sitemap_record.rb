module Cms
  class SitemapElement < ActiveRecord::Base
    extend Enumerize

    attr_accessible *attribute_names

    belongs_to :page, polymorphic: true

    attr_accessible :page

    enumerize :changefreq, in: [:default, :always, :hourly, :daily, :weekly, :monthly, :yearly, :never], default: :default

    before_save :set_defaults

    def set_defaults
      self.priority = 0.5 if priority.blank?
      #self.display_on_sitemap ||= true
    end

    def self.entries

      local_entries = []
      SitemapElement.all.map do|e|
        I18n.available_locales.each do |locale|
          entry = { loc: e.url(locale), changefreq: e.change_freq, priority: e.priority}
          local_lastmod = e.lastmod(locale)
          entry[:lastmod] = local_lastmod.to_datetime.strftime if local_lastmod.present?
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
      page.try{|p| "http://ltstudio.com.ua#{p.url(locale)}" }
    end

    def lastmod locale = I18n.locale
      page.try{|p| p.updated_at }
    end

    def change_freq
      if changefreq == :default
        return :monthly
      end

      return changefreq
    end
  end
end