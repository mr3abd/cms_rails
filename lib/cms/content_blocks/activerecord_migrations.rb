module Cms
  module ContentBlocks
    module ActiveRecordExtensions
      module ClassMethods

        def create_content_block_table(options = {})
          options[:class_name] ||= Cms.config.content_block_class.name

          table_name = Utils.resolve_table_name(options)
          cols = normalize_content_block_columns(options)


          connection.create_table table_name do |t|
            cols.each do |col_name, col_type|
              t.send col_type, col_name
            end
          end



          if Cms.config.use_translations
            c = Object.const_get(options[:class_name]) # model class
            translation_columns = normalize_content_block_translation_columns(options)
            c.initialize_content_block_translation

            c.create_translation_table!(translation_columns)
          end
        end

        def normalize_content_block_columns(options = {})
          default_columns = {
              type: :string,
              attachable_id: :integer,
              attachable_type: :string,
              attachable_field_name: :string,
              published: :boolean,
              sorting_position: :integer,
              title: :string,
              description: :text,
              image: :attachment
          }

          additional_columns = {

          }

          Utils.normalize_columns(default_columns: default_columns, additional_columns: additional_columns)
        end

        def normalize_content_block_translation_columns(options = {})
          default_translation_columns = {
              title: :string
          }

          defaults = {
              default_translation_columns: {
                  title: :string,
                  description: :text
              },
              additional_translation_columns: {

              }
          }

          Utils.normalize_translation_columns(defaults.merge(options))
        end

        def drop_content_block_table
          return unless self.table_exists?

          if Cms.config.use_translations
            self.drop_translation_table!
          end
          connection.drop_table self.table_name

        end

      end
    end
  end
end

ActiveRecord::Base.send(:extend, Cms::ContentBlocks::ActiveRecordExtensions::ClassMethods)