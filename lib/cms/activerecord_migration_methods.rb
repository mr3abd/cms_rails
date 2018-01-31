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
          columns = Cms.column_names(Cms::GlobalizeExtension.resolve_resource_table_name(model_or_resource_name), nil, ["text", "string"])
        end

        Cms::GlobalizeExtension.create_translation_table(model_or_resource_name, *columns)
        #puts "-- #{model.try(:name) || model}.create_translation_table # #{model.try(:translation_class).try(:table_name) || model}"
      end

      def drop_translation_table(model_or_resource_name, *columns)
        if self.reverting?
          if columns.first.to_s == "all"
            columns = Cms.column_names(Cms::GlobalizeExtension.resolve_resource_table_name(model_or_resource_name), nil, ["text", "string"])
          end
          Cms::GlobalizeExtension.create_translation_table(model_or_resource_name, *columns)
          return
        end
        Cms::GlobalizeExtension.drop_translation_table!(model_or_resource_name)
      end
    end
  end
end

ActiveRecord::Migration.send(:include, ActiveRecordExtensions::Globalize::SchemaStatements)