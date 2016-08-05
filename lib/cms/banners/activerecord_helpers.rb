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

          attachment_names = normalize_banner_columns(options).keep_if{|k, v| v == :attachment }.keys

          if attachment_names.try(&:any?)
            attachment_names.each do |attachment_name|
              has_attached_file attachment_name
              do_not_validate_attachment_file_type attachment_name
              attr_accessible attachment_name
              allow_delete_attachment attachment_name
            end
          end

          belongs_to :attachable, polymorphic: true

          scope :published, -> { where(published: 't') }
          scope :sort_by_sorting_position, ->{ order("sorting_position asc") }


          return unless self.table_exists?
          if Cms.config.use_translations
            initialize_banner_translation
          end

        end

        def normalize_banner_columns(options = {})
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

          Utils.normalize_columns(default_columns: default_columns, additional_columns: additional_columns)
        end

        def normalize_banner_translation_columns(options = {})

          defaults = {
              default_translation_columns: {
                  name: :string
              },
              additional_translation_columns: {
                  description: :text
              }
          }

          Utils.normalize_translation_columns(defaults.merge(options))
        end

        def initialize_banner_translation
          Utils.initialize_translation(self, normalize_banner_translation_columns)
        end



        def acts_as_banner_options
          opts = class_variable_defined?(:@@acts_as_banner_options) ? class_variable_get(:@@acts_as_banner_options) : {}
        end

        def attachment_names
          [:image]
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