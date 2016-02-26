module Cms
  module Banners
    module ActiveRecordExtensions
      module ClassMethods
        def acts_as_banner options = {}



          class_variable_set(:@@acts_as_banner_options, options)
          if mod = options[:base_articles]
            self.send(:extend, mod)
          end

          self.attr_accessible *attribute_names
          initialize_all_attachments = options[:initialize_all_attachments]
          initialize_all_attachments ||= false

          attachment_names = normalize_columns(options).keep_if{|k, v| v == :attachment }.keys

          if attachment_names.try(&:any?)
            attachment_names.each do |attachment_name|
              has_attached_file attachment_name
              do_not_validate_attachment_file_type attachment_name
              attr_accessible attachment_name
              allow_delete_attachment attachment_name
            end
          end

          belongs_to :attachable, polymorphic: true

          scope :published, -> { where(published: true) }


          return unless self.table_exists?
          if Cms.config.use_translations
            initialize_translation
          end

        end

        def initialize_translation
          translation_column_names = normalize_translation_columns(acts_as_banner_options).keys
          self.translates(*translation_column_names)
          accepts_nested_attributes_for :translations
          attr_accessible :translations, :translations_attributes
        end

        def acts_as_banner_options
          opts = class_variable_get(:@@acts_as_banner_options) || {}
        end

        def attachment_names
          [:image]
        end

        def normalize_columns(options = {})
          c = self

          default_columns = {
              attachable_type: :string,
              attachable_id: :integer,
              attachable_field_name: :string,
              published: :boolean,
              sorting_position: :integer,
              name: :string,
              image: :attachment
          }

          additional_columns = {
              description: :text,
              icon: :attachment
          }

          [:description, :icon].each do |additional_column|
            if !options[additional_column]
              additional_columns.delete(additional_column)
            end
          end

          cols = default_columns.merge(additional_columns)
        end

        def normalize_translation_columns(options = {})
          default_translation_columns = {
              name: :string
          }

          additional_translation_columns = {
              description: :text
          }

          [:description].each do |additional_column|
            if !options[additional_column]
              additional_translation_columns.delete(additional_column)
            end
          end

          translation_columns = default_translation_columns.merge(additional_translation_columns)

          translation_columns
        end

        def resolve_table_name(options = {})
          table_name = self.name.underscore.pluralize
        end

        def create_banner_table(options = {})
          options[:class_name] ||= Cms.config.banner_class.name
          options[:table_name] ||= options[:class_name].underscore.pluralize

          table_name = resolve_table_name(options)
          cols = normalize_columns(options)
          translation_cols = normalize_translation_columns(options)

          connection.create_table table_name do |t|
            cols.each do |col_name, col_type|
              t.send col_type, col_name
            end
          end



          if Cms.config.use_translations
            c = Object.const_get(options[:class_name]) # model class
            c.initialize_translation
            translation_columns = c.normalize_translation_columns(options)
            c.create_translation_table!(translation_columns)
          end
        end



        def drop_banner_table
          return unless self.table_exists?

          if Cms.config.use_translations
            self.drop_translation_table!
          end
          connection.drop_table self.table_name

        end
      end

      module InstanceMethods
        def set_default_title_html_tag
          self.title_html_tag = "div" if self.title_html_tag.blank?
        end
      end
    end
  end
end


ActiveRecord::Base.send(:extend, Cms::Banners::ActiveRecordExtensions::ClassMethods)
ActiveRecord::Base.send(:include, Cms::Banners::ActiveRecordExtensions::InstanceMethods)