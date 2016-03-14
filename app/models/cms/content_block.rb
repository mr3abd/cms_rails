module Cms
  class ContentBlock < ActiveRecord::Base
    self.table_name = :content_blocks

    #acts_as_content_block



    def self.include_translations?
      Cms::Config.use_translations && respond_to?(:translates?)
    end






    scope :by_key, ->(key) { where(key: key) }
    scope :by_field, ->(field) { where(attachable_field_name: field) }
  end
end