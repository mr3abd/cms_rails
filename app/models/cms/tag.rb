module Cms
  class Tag < ActiveRecord::Base
    self.table_name = :cms_tags
    attr_accessible *attribute_names
    has_many :taggings

    attr_accessible :taggable


    if Cms.config.use_translations
      globalize :name, :url_fragment
    end

    def self.taggable_associations
      (self.class_variable_get(:@@taggable_associations) rescue []) || []
    end

    def self.taggable_models
      taggable_associations.map{|k| a = reflections[k.to_s]; next nil if a.nil?;  a.klass }.select{|c| !c.nil? }
    end

    def self.cacheable_taggable_models
      taggable_models.select{|c| c.respond_to?(:cacheable?) && c.cacheable? }
    end

    has_cache do
      pages *self.class.cacheable_taggable_models
    end

    scope :available, proc { joins(:taggings) }
    scope :available_for, ->(records){ records.empty? ? available : available.where(cms_taggings: { taggable_type: records.map{|a| a.class.to_s }, taggable_id: records.map(&:id) }).group("cms_tags.id") }

    # def name(locale = I18n.locale)
    #   self.translations_by_locale[locale]['name']
    # end
  end
end