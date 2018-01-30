module ActiveRecordExtensions
  module Globalize
    module SchemaStatements
      def create_translation_table(model, *columns)
        if self.reverting?
          model.drop_translation_table!
          puts "-- #{model.name}.drop_translation_table # #{model.translation_class.table_name}"
          return
        end

        if columns.first.to_s == "all"
          columns = Cms.column_names(model.table_name, nil, ["text", "string"])
        end

        Cms::GlobalizeExtension.create_translation_table(model, *columns)
        puts "-- #{model.try(:name) || model}.create_translation_table # #{model.try(:translation_class).try(:table_name) || model}"
      end
    end
  end
end

ActiveRecord::Migration.send(:include, ActiveRecordExtensions::Globalize::SchemaStatements)