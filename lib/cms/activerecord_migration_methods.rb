module ActiveRecordExtensions
  module Globalize
    module SchemaStatements
      def create_translation_table(model_or_resource_name, *columns)
        if model_or_resource_name.is_a?(Class)
          model = model_or_resource_name
          resource_name = nil
        else
          model = nil
          resource_name = model_or_resource_name
        end
        if self.reverting?
          Cms::GlobalizeExtension.drop_translation_table!(model_or_resource_name)

          #puts "-- #{model.name}.drop_translation_table # #{model.translation_class.table_name}"
          return
        end

        if columns.first.to_s == "all"
          columns = Cms.column_names(model.table_name, nil, ["text", "string"])
        end

        Cms::GlobalizeExtension.create_translation_table(model, *columns)
        #puts "-- #{model.try(:name) || model}.create_translation_table # #{model.try(:translation_class).try(:table_name) || model}"
      end
    end
  end
end

ActiveRecord::Migration.send(:include, ActiveRecordExtensions::Globalize::SchemaStatements)