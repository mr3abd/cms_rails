require 'paperclip'

module Cms
  class Page < ActiveRecord::Base
    self.table_name = :pages
    #attr_accessible *attribute_names

    extend Cms::Caching::ClassMethods
    include Cms::Caching::InstanceMethods

    has_seo_tags
    has_sitemap_record

    def self.include_translations?
      respond_to?(:translates?) && translates?
    end


    #if self.column_names.include?('banner_file_name')
      self.has_attached_file :banner
      attr_accessible :banner
      do_not_validate_attachment_file_type :banner
    #end


    self.has_attached_file :bottom_banner
    attr_accessible :bottom_banner
    do_not_validate_attachment_file_type :bottom_banner


    if respond_to?(:translates)
      translates :url
      accepts_nested_attributes_for :translations
      attr_accessible :translations, :translations_attributes

      class Translation
        self.table_name = :page_translations
        attr_accessible *attribute_names
        belongs_to :page, class_name: "Cms::Page"
      end
    end

    #after_save :reload_routes, if: proc { self.url_changed? }

    def self.default_url
      # page_key = self.name.split("::").last.underscore
      # I18n.t("pages.#{page_key}.title", raise: true) rescue page_key.humanize.parameterize
      self.name.split("::").last.underscore.humanize.parameterize
    end

    def self.default_head_title
      page_key = self.name.split("::").last.underscore
      I18n.t("pages.#{page_key}.head_title", raise: true) rescue page_key.humanize.parameterize
    end

    def self.disabled
      false
    end

    def reload_routes
      DynamicRouter.reload
    end
  end
end