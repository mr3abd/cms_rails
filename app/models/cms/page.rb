require 'paperclip'

module Cms
  class Page < ActiveRecord::Base
    self.table_name = :pages
    #attr_accessible *attribute_names

    # include Cms::PageUrlHelpers
    # extend Cms::Caching::ClassMethods
    # include Cms::Caching::InstanceMethods
    has_url
    has_cache

    has_seo_tags
    has_sitemap_record

    def self.include_translations?
      Cms::Config.use_translations && respond_to?(:translates?)
    end


    # #if self.column_names.include?('banner_file_name')
    #   self.has_attached_file :banner
    #   attr_accessible :banner
    #   do_not_validate_attachment_file_type :banner
    # #end
    #
    #
    # self.has_attached_file :bottom_banner
    # attr_accessible :bottom_banner
    # do_not_validate_attachment_file_type :bottom_banner

    def self.initialize_globalize
      translates :url
      accepts_nested_attributes_for :translations
      attr_accessible :translations, :translations_attributes

      Translation.class_eval do
        self.table_name = :page_translations
        attr_accessible *attribute_names
        belongs_to :page, class_name: "Cms::Page"
      end
    end

    if Cms::Config.use_translations && respond_to?(:translates) && self.table_exists?
      self.initialize_globalize
    end



    #after_save :reload_routes, if: proc { self.url_changed? }
    #after_save :reload_routes

    def default_url
      # page_key = self.name.split("::").last.underscore
      # I18n.t("pages.#{page_key}.title", raise: true) rescue page_key.humanize.parameterize
      page_key.humanize.parameterize
    end

    def page_key
      self.class.name.split("::").last.underscore
    end

    def self.default_head_title
      I18n.t("pages.#{page_key}.head_title", raise: true) rescue page_key.humanize.parameterize
    end

    def self.disabled
      false
    end

    def reload_routes
      #DynamicRouter.reload
      Rails.application.routes_reloader.reload!
    end

    def name(locale = I18n.locale)
      name = nil
      if self.class.include_translations?
        name = self.translations_by_locale[locale].try(:name)
      end

      if name.blank?
        I18n.with_locale(locale) do
          name = I18n.t("pages.#{page_key}.name", raise: true) rescue I18n.t("pages.#{page_key}", raise: true) rescue page_key.humanize
        end
      end

      name

    end


  end
end