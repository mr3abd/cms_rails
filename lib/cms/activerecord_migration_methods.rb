module ActiveRecordExtensions
  module Globalize
    module SchemaStatements
      def create_translation_table(model, **columns)
        self
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::SchemaStatements.send(:include, ActiveRecordExtensions::Globalize::SchemaStatements)