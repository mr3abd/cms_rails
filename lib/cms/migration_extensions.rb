module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module SchemaStatements
      def create_form_table(table_name, &block)
        create_table table_name do |t|
          t.string :referer
          t.integer :session_id
          t.string :locale

          if block_given?
            block.call(t)
          end

          t.timestamps null: false
        end
      end
    end
  end
end