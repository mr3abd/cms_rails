module Cms
  module GlobalizeExtension

    def self.connection
      ActiveRecord::Base.connection
    end

    def self.resolve_table_name_prefix(model_or_resource_name)
      ""
    end

    def self.resolve_resource_name(model_or_resource_name)
      if model_or_resource_name.is_a?(Class)
        model_or_resource_name.name.underscore
      elsif model_or_resource_name.is_a?(Symbol) || model_or_resource_name.is_a?(String)
        model_or_resource_name.to_s.singularize
      end
    end

    def self.resolve_translations_table_name(model_or_resource_name)
      resolve_resource_name(model_or_resource_name) + "_translations"
    end

    def self.resolve_resource_table_name(model_or_resource_name)
      resolve_resource_name(model_or_resource_name).pluralize
    end

    def self.create_translation_table(model_or_resource_name, *columns)
      options = columns.extract_options!
      columns = _calculate_globalize_columns(model_or_resource_name, *columns)

      if model_or_resource_name.respond_to?(:initialize_globalize)
        model_or_resource_name.initialize_globalize
      end





      _create_translation_table!(model_or_resource_name, columns, options)
    end

    def self._create_translation_table!(model_or_resource_name, fields = {}, options = {})
      extra = options.keys - [:migrate_data, :remove_source_columns, :unique_index]
      if extra.any?
        raise ArgumentError, "Unknown migration #{'option'.pluralize(extra.size)}: #{extra}"
      end
      @fields = fields
      # If we have fields we only want to create the translation table with those fields
      complete_translated_fields if fields.blank?
      #validate_translated_fields if options[:skip_validate_translated_fields] != false
      translation_table_name = resolve_translations_table_name(model_or_resource_name)
      _create_translation_table(model_or_resource_name)
      _add_translation_fields(model_or_resource_name, fields)
      #create_translations_index(options)
      #clear_schema_cache!
    end

    def self._add_translation_fields(model_or_resource_name, fields)
      translations_table_name = resolve_translations_table_name(model_or_resource_name)
      connection.change_table(translations_table_name) do |t|
        fields.each do |name, options|
          if options.is_a? Hash
            t.column name, options.delete(:type), options
          else
            t.column name, options
          end
        end
      end
    end

    def self._create_translation_table(model_or_resource_name)
      resource_name = resolve_resource_name(model_or_resource_name)
      resource_table_name = resolve_resource_table_name(model_or_resource_name)
      translations_table_name = resolve_translations_table_name(model_or_resource_name)
      connection.create_table(translations_table_name) do |t|
        t.references resource_table_name.sub(/^#{resolve_table_name_prefix(model_or_resource_name)}/, '').singularize, :null => false, :index => false
        t.string :locale, :null => false
        t.timestamps :null => false
      end
    end

    def self._calculate_globalize_columns(model_or_resource_name, *columns)
      resource_table_name = resolve_resource_table_name(model_or_resource_name)
      if columns.any?
        stringified_column_names = columns.map(&:to_s)
        original_table_columns = ActiveRecord::Base.connection.columns(resource_table_name)
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


          original_class::Translation.class_variable_set(:@@_resource_class, resource_class)
          original_class::Translation.class_variable_set(:@@_resource_association_name, resource_association_name)

          translation_belongs_to_options = {}

          if Rails::VERSION::MAJOR >= 5
            translation_belongs_to_options[:class_name] = resource_class.to_s
            translation_belongs_to_options[:optional] = true
          else
            translation_belongs_to_options[:class_name] = resource_class
          end

          original_class::Translation.class_eval do
            self.table_name = resource_translation_table_name
            attr_accessible *attribute_names
            belongs_to resource_association_name, translation_belongs_to_options

            def resource
              send(self.class.resource_association_name)
            end

            def self.resource_association_name
              self.class_variable_get(:@@_resource_association_name)
            end

            def self.resource_class
              self.class_variable_get(:@@_resource_class)
            end

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



      if !self.instance_methods.include?(:translated?)
        include Translated
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

    def create_translation_table *columns
      GlobalizeExtension.create_translation_table(self, columns)
    end

    def drop_translation_table(*args)
      drop_translation_table!(*args)
    end


  end

  module Translated
    def is_translated?(locale = I18n.locale)
      attrs = self.class.class_variable_get(:@@_translated_scope_attrs)
      begin
        t =  self.translations.where(locale: locale.to_s).first
      rescue
        t = nil
      end
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
end
ActiveRecord::Base.send(:extend, Cms::GlobalizeExtension)