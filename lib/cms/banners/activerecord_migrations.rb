module Cms
  module Banners
    module ActiveRecordMigrations
      module ClassMethods

        def create_banner_table(options = {})
          options[:class_name] ||= Cms.config.banner_class.name

          table_name = Utils.resolve_table_name(options)
          cols = normalize_banner_columns(options)


          connection.create_table table_name do |t|
            cols.each do |col_name, col_type|
              t.send col_type, col_name
            end
          end



          if Cms.config.use_translations
            c = Object.const_get(options[:class_name]) # model class
            c.initialize_banner_translation
            translation_columns = normalize_banner_translation_columns(options)
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
    end
  end
end

ActiveRecord::Base.send(:extend, Cms::Banners::ActiveRecordMigrations::ClassMethods)
