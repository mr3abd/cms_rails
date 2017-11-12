module Cms
  module GlobalizeExtension
    def globalize(*attrs)
      class_variable_set("@@globalize_attributes", attrs)


      options = attrs.last
      if !options.is_a?(Hash)
        options = {}
      else
        attrs.pop
        #translation_table_name = options.delete(:translation_table_name)
        class_variable_set("@@globalize_translation_table_name", options.delete(:translation_table_name))
      end


      class << self

        define_method :initialize_globalize do
          use_last_name_part = false
          original_class_name = self.name.split("::")
          original_class_name = original_class_name[0, original_class_name.length].join("::")
          #puts "original_class_name: #{original_class_name}"
          original_class = Object.const_get(original_class_name)
          attrs = original_class.class_variable_get("@@globalize_attributes")
          if attrs.first.to_s == "all"
            begin
              attrs = Cms.column_names(self.table_name, nil, ["text", "string"])
            rescue
              return nil
            end
          end

          #attrs = instance_variable_get("@globalize_attributes")
          #puts "attrs: #{attrs.inspect}"
          original_class.translates *attrs
          accepts_nested_attributes_for :translations
          attr_accessible :translations, :translations_attributes
          resource_class = self


          if use_last_name_part
            resource_association_name = resource_class.name.split("::").last.underscore.to_sym
          else
            resource_association_name = resource_class.name.gsub("::", "_").underscore.to_sym
          end
          resource_translation_table_name = resource_class.class_variable_get(:@@globalize_translation_table_name) rescue nil
          resource_translation_table_name = "#{resource_association_name}_translations" if resource_translation_table_name.blank?





          original_class::Translation.class_eval do
            self.table_name = resource_translation_table_name
            attr_accessible *attribute_names
            belongs_to resource_association_name, class_name: resource_class

            #validates_presence_of :name, if: proc{ self.locale.to_s == 'uk' }

            before_save :initialize_url_fragment
            def initialize_url_fragment
              if self.respond_to?(:url_fragment) && self.respond_to?(:url_fragment=)
                return true if self.url_fragment.present?
                name_method = :id
                if self.respond_to?(:name)
                  name_method = :name
                elsif self.respond_to?(:title)
                  name_method = :title
                end

                if self.send(name_method).blank?
                  self.url_fragment = ""
                elsif self.url_fragment.blank?
                  locale = self.locale
                  locale = :ru if locale.to_sym == :uk
                  I18n.with_locale(locale) do
                    self.url_fragment = self.send(name_method).to_s.parameterize
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

        define_method :translated_scope do |*attrs|
          self.class_variable_set(:@@_translated_scope_attrs, attrs)
          if !self.respond_to?(:translated)
            scope :translated, ->(locale = I18n.locale) {
              attrs = self.class_variable_get(:@@_translated_scope_attrs)
              translation_table = self.translation_class.table_name
              relation = joins(:translations).where("#{translation_table}.locale = ?", locale)
              attrs.each do |attr|
                full_attr_name = "#{translation_table}.#{attr}"
                relation = relation.where("#{full_attr_name} IS NOT NULL AND #{full_attr_name} <> ''")
              end

              relation
            }
          end
        end
      end

      if !instance_methods.include?(:translated?)
        define_method :translated? do |locale = I18n.locale|
          attrs = self.class.class_variable_get(:@@_translated_scope_attrs)
          t =  self.translations_by_locale[locale.to_s] rescue nil
          translated = !t.nil?
          attrs.each do |attr|
            if !translated
              break
            end

            if t && t.send(attr).blank?
              translated = false
            end
          end

          translated
        end
      end

      stringified_attrs = attrs.map(&:to_s)
      if stringified_attrs.include?(:name)
        translated_scope_attr = :name
      elsif stringified_attrs.include?(:title)
        translated_scope_attr = :title
      else
        translated_scope_attr = stringified_attrs.first
      end

      translated_scope(translated_scope_attr)


      if self.table_exists?
        self.initialize_globalize
      end
    end

    def globalize_attributes
      class_variable_get("@@globalize_attributes") || [] rescue []
    end

    def _calculate_globalize_columns(*columns)
      if columns.any?
        stringified_column_names = columns.map(&:to_s)
        original_table_columns = ActiveRecord::Base.connection.columns(self.table_name)
        normalized_columns = original_table_columns.map{|c|
          type = nil
          if c.respond_to?(:cast_type)
            type = c.cast_type.class.name.split(":").last.underscore
          end

          if type.nil? || type.start_with?("sq_")
            type = c.type
          end

          {name: c.name,
           type: type
          }
        }
        columns = Hash[normalized_columns.select{|c| c[:name].to_s.in?(stringified_column_names) }.map{|item| [item[:name].to_sym, item[:type].to_sym] }]
      end
      if columns.blank?
        columns = {}
      end

      columns
    end

    def create_translation_table *columns
      columns = _calculate_globalize_columns(*columns)

      initialize_globalize
      create_translation_table!(columns)
    end

    def drop_translation_table(*args)
      drop_translation_table!(*args)
    end
  end
end
ActiveRecord::Base.send(:extend, Cms::GlobalizeExtension)