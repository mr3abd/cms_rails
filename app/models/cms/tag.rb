module Cms
  class Tag < ActiveRecord::Base
    self.table_name = :cms_tags
    attr_accessible *attribute_names
    has_many :taggings





    attr_accessible :taggable


    if Cms.config.use_translations
      globalize :name, :url_fragment
    end



    # def name(locale = I18n.locale)
    #   self.translations_by_locale[locale]['name']
    # end
  end
end