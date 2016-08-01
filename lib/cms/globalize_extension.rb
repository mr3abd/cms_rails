module Cms
  module GlobalizeExtension
    def globalize(*attrs)

      class_variable_set("@@globalize_attributes", attrs)
      class << self

        define_method :initialize_globalize do
          use_last_name_part = false
          original_class_name = self.name.split("::")
          original_class_name = original_class_name[0, original_class_name.length].join("::")
          #puts "original_class_name: #{original_class_name}"
          original_class = Object.const_get(original_class_name)
          attrs = original_class.class_variable_get("@@globalize_attributes")
          #attrs = instance_variable_get("@globalize_attributes")
          #puts "attrs: #{attrs.inspect}"
          original_class.translates *attrs
          accepts_nested_attributes_for :translations
          attr_accessible :translations, :translations_attributes
          resource_class = self


          if use_last_name_part
            resource_association_name = resource_class.name.split("::").last.underscore.to_sym
          else
            resource_association_name = resource_class.name.gsub("::", "_").last.underscore.to_sym
          end
          resource_translation_table_name = "#{resource_association_name}_translations"



          original_class::Translation.class_eval do
            self.table_name = resource_translation_table_name
            attr_accessible *attribute_names
            belongs_to resource_association_name, class_name: resource_class

            #validates_presence_of :name, if: proc{ self.locale.to_s == 'uk' }

            before_save :initialize_url_fragment
            def initialize_url_fragment
              if self.respond_to?(:url_fragment) && self.respond_to?(:url_fragment=)

                if self.name.blank?
                  self.url_fragment = ""
                elsif self.url_fragment.blank?
                  locale = self.locale
                  locale = :ru if locale.to_sym == :uk
                  I18n.with_locale(locale) do
                    self.url_fragment = self.name.parameterize
                  end
                end

              end
            end
          end

          attrs.each do |attr|
            define_method(attr) do |locale = I18n.locale|
              self.translations_by_locale[locale].try(attr.to_sym)
            end
          end
        end

      end




      if self.table_exists?
        self.initialize_globalize
      end
    end

    def create_translation_table *columns

      if columns.any?
        stringified_column_names = columns.map(&:to_s)
        normalized_columns = self.columns.map{|c| {name: c.name, type: c.cast_type.class.name.split(":").last.underscore}}
        columns = Hash[normalized_columns.select{|c| c[:name].to_s.in?(stringified_column_names) }.map{|item| [item[:name].to_sym, item[:type].to_sym] }]
      end
      if columns.blank?
        columns = {}
      end

      initialize_globalize
      create_translation_table!(columns)
    end

    def drop_translation_table(*args)
      drop_translation_table!(*args)
    end
  end
end
ActiveRecord::Base.send(:extend, Cms::GlobalizeExtension)