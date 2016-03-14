module Cms
  module Articles
    module ActiveRecordExtensions
      module ClassMethods

        def create_article_table(options = {})
          return if self.table_exists?

          connection.create_table self.table_name do |t|
            t.boolean :published
            t.string :name
            t.text :short_description
            t.text :content
            t.string :url_fragment
            t.has_attached_file :avatar


            if options[:author] != false
              t.belongs_to :author
            end

            t.timestamps null: false
          end
        end

        def drop_article_table
          return unless self.table_exists?

          connection.drop_table self.table_name
        end

      end
    end
  end
end

ActiveRecord::Base.send(:extend, Cms::Articles::ActiveRecordExtensions::ClassMethods)