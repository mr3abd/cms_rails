module Cms
  class Tag < ActiveRecord::Base
    self.table_name = :cms_tags
    attr_accessible *attribute_names
    has_many :taggings





    attr_accessible :taggable


    if Cms.config.use_translations
      def self.initialize_globalize
        translates :name, :url_fragment
        accepts_nested_attributes_for :translations
        attr_accessible :translations, :translations_attributes

        Translation.class_eval do
          self.table_name = :cms_tag_translations
          attr_accessible *attribute_names
          belongs_to :tag, class_name: "Tag"

          before_save :initialize_url_fragment
          def initialize_url_fragment
            if self.respond_to?(:url_fragment) && self.respond_to?(:url_fragment=)

              if self.name.blank?
                self.url_fragment = ""
              elsif self.url_fragment.blank?
                I18n.with_locale(self.locale) do
                  self.url_fragment = self.name.parameterize
                end
              end

            end
          end
        end
      end

      if self.table_exists?
        self.initialize_globalize
      end
    end



    # def name(locale = I18n.locale)
    #   self.translations_by_locale[locale]['name']
    # end
  end
end