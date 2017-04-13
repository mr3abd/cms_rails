module Cms
  module NameHelper
    def human_attribute_name(attr, options = {})
      attr = attr.to_s
      model_key = self.name.underscore
      versions = ["activerecord.attributes.#{model_key}.#{attr}", "activerecord.attributes.#{attr}"]
      str = Cms.t(versions)
      if str.is_a?(Hash) || str.is_a?(Array)
        model_key.humanize
      else
        str
      end
    end
  end
end

ActiveRecord::Base.send(:extend, Cms::NameHelper)