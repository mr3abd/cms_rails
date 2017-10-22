module ActiveRecordExtensions
  module Globalize
    module SchemaStatements
      def create_translation_table(model, *columns)
        if self.reverting?
          return model.drop_translation_table!
        end

        model.create_translation_table(*columns)
      end
    end
  end
end

ActiveRecord::Migration.send(:include, ActiveRecordExtensions::Globalize::SchemaStatements)