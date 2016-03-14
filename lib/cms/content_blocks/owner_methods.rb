module Cms
  module ContentBlocks
    module OwnerMethods
      module ClassMethods
        def has_content_blocks(name = nil, **options)
          multiple = options[:multiple]
          multiple = true if multiple.nil?

          reflection_method = :has_one
          reflection_method = :has_many if multiple

          name ||=  multiple ? :content_blocks : :content_block
          return false if self._reflections.keys.include?(name.to_s)

          options[:base_class] ||= options[:class]
          options[:class] ||= options[:base_class]
          options[:base_class] ||= Cms.config.banner_class

          send reflection_method, name, -> { where(attachable_field_name: name) }, as: :attachable, class_name: options[:base_class], dependent: :destroy, autosave: true
          accepts_nested_attributes_for name, allow_destroy: true
          attr_accessible name, "#{name}_attributes"


          store_field_name(:@@banner_field_names, name)


          return options
        end

        def has_content_block(name = nil, **options)
          options[:multiple] = false
          has_content_blocks(name, options)
        end
      end
    end
  end
end


ActiveRecord::Base.send(:extend, Cms::ContentBlocks::OwnerMethods::ClassMethods)