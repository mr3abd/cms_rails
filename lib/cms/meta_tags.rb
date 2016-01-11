module Cms
  class MetaTags < ActiveRecord::Base
    self.table_name = :seo_tags

    attr_accessible *attribute_names
    belongs_to :page, polymorphic: true
    attr_accessible :page

    def self.include_translations?
      respond_to?(:translates?) && translates?
    end

    if respond_to?(:translates)
      translates :title, :keywords, :description
      accepts_nested_attributes_for :translations
      attr_accessible :translations, :translations_attributes

      class Translation
        attr_accessible *attribute_names
        belongs_to :meta_tags
      end
    end

    #alias :head_title :title

    
  end
end