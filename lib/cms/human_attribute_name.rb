module Cms
  module NameHelper
    def human_attribute_name(attr, options = {})
      attr = attr.to_s
      model_key = self.name.underscore
      versions = ["activerecord.attributes.#{model_key}.#{attr}"]

      if model_key.end_with?('/translation')
        original_model_key = model_key.gsub('/translation', '')
        versions << "activerecord.attributes.#{original_model_key}.#{attr}"
      end

      versions << "activerecord.attributes.#{attr}"

      str = nil
      versions.each do |v|
        str = I18n.t(v, raise: true) rescue nil
        if str.is_a?(Hash) || str.is_a?(Array)
          str = nil
        end
        break if str.present?
      end



      if str.blank?
        attr.humanize
      else
        str
      end
    end
  end
end

ActiveRecord::Base.send(:extend, Cms::NameHelper)