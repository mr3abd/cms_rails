module Cms
  module Taggable
    module ActiveRecordExtensions
      module ClassMethods

      end

      module InstanceMethods
        def initialize_url_fragment
          if self.respond_to?(:url_fragment) && self.respond_to?(:url_fragment=)
            self.url_fragment = self.name.parameterize if self.url_fragment.blank?
          end
        end

        def to_param
          fragment = nil
          if self.respond_to?(:url_fragment) && self.url_fragment.present?
            fragment = self.url_fragment
          end

          fragment ||= self.id.to_s

          return fragment
        end
      end
    end
  end
end


ActiveRecord::Base.send(:extend, Cms::Articles::ActiveRecordExtensions::ClassMethods)
ActiveRecord::Base.send(:include, Cms::Articles::ActiveRecordExtensions::InstanceMethods)