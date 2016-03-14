module Cms
  module Utils
    def self.normalize_columns(options = {})


      default_columns = options[:default_columns] || {}

      additional_columns = options[:additional_columns] || {}

      additional_columns.each do |additional_column|
        if !options[additional_column]
          additional_columns.delete(additional_column)
        end
      end

      cols = default_columns.merge(additional_columns)
    end

    def self.normalize_translation_columns(options = {})
      default_translation_columns = options[:default_translation_columns] || {}

      additional_translation_columns = options[:additional_translation_columns] || {}

      additional_translation_columns.each do |additional_column|
        if !options[additional_column]
          additional_translation_columns.delete(additional_column)
        end
      end

      translation_columns = default_translation_columns.merge(additional_translation_columns)

      translation_columns
    end

    def self.resolve_table_name(options = {})
      if options[:table_name].present?
        return options[:table_name]
      end

      klass = options[:class] || options[:class_name]
      if klass.blank?
        raise ArgumentError, "please provide class or class_name option"
      end

      if klass.is_a?(String)
        klass = Object.const_get(klass)
      end
      table_name = klass.name.split("::").last.underscore.pluralize
    end

    def self.initialize_translation(base, translation_columns = {})
      translation_column_names = translation_columns.keys
      base.translates(*translation_column_names)
      base.accepts_nested_attributes_for :translations
      base.attr_accessible :translations, :translations_attributes
    end
  end
end