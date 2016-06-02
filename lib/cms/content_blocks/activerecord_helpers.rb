module Cms
  module ContentBlocks
    module ActiveRecordExtensions
      module ClassMethods
        def acts_as_content_block options = {}

          class_variable_set(:@@acts_as_content_block_options, options)
          if mod = options[:base_articles]
            self.send(:extend, mod)
          end

          self.attr_accessible *attribute_names


          belongs_to(:attachable, polymorphic: true, autosave: true)
          attr_accessible :attachable

          scope :published, -> { where(published: true) }


          return unless self.table_exists?
          if Cms.config.use_translations
            initialize_banner_translation
          end

          has_cache(false)
          define_method "cache_instances" do
            attachable.try{|a| [a] }
          end


          #after_save :trigger_parent_change


        end

        def trigger_parent_change
          attachable.try()
        end



        def acts_as_content_block_options
          opts = class_variable_get(:@@acts_as_content_block_options) || {}
        end


        def initialize_content_block_translation

          Utils.initialize_translation(self, normalize_content_block_translation_columns)
        end
      end

      module InstanceMethods

      end
    end
  end
end

ActiveRecord::Base.send(:extend, Cms::ContentBlocks::ActiveRecordExtensions::ClassMethods)
ActiveRecord::Base.send(:include, Cms::ContentBlocks::ActiveRecordExtensions::InstanceMethods)