module Cms
  module NameHelper
    def human_attribute_name(attr, options = {})
      attr = attr.to_s
      model_key = self.name.underscore
      versions = ["activerecord.attributes.#{model_key}.#{attr}", "activerecord.attributes.#{attr}"]
      Cms.t(versions)
    end
  end
end

ActiveRecord::Base.send(:extend, Cms::NameHelper)