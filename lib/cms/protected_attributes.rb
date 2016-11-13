module Cms
  module ProtectedAttributes
    module ActiveRecord
      module ClassMethods
        def attr_accessible *args

        end
      end
    end
  end
end

if ActiveRecord::Base.respond_to?(:attr_accessible)
  ActiveRecord::Base.send(:extend, Cms::ProtectedAttributes::ActiveRecord::ClassMethods)
end