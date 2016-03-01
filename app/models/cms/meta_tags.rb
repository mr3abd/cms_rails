module Cms
  class MetaTags < ActiveRecord::Base
    self.table_name = :seo_tags

    attr_accessible *attribute_names
    belongs_to :page, polymorphic: true
    attr_accessible :page

    def self.include_translations?
      Cms::Config.use_translations && respond_to?(:translates?)
    end

    def self.initialize_globalize
      translates :title, :keywords, :description
      accepts_nested_attributes_for :translations
      attr_accessible :translations, :translations_attributes

      Translation.class_eval do
        self.table_name = :seo_tag_translations
        attr_accessible *attribute_names
        belongs_to :meta_tags
      end
    end

    if Cms::Config.use_translations && respond_to?(:translates) && self.table_exists?
      initialize_globalize
    end

    #alias :head_title :title

    def self.configure_rails_admin(config)
      m = self

      config.include_models(m)
      if Cms.config.use_translations && self.table_exists?
        config.model m do
          visible false
          field :translations, :globalize_tabs
        end

        config.model m.translation_class do
          visible false
          field :locale, :hidden
          field :title
          field :keywords
          field :description
        end
      else
        config.model m do
          visible false
          field :title
          field :keywords
          field :description
        end
      end

    end

    
  end
end