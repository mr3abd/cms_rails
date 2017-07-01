module Cms
  module Helpers
    module DateHelper
      module ClassMethods
        def date_field(attr)
          define_method "#{attr}" do
            v = self[attr.to_s]
            date = strptime(v, I18n.t("date.formats.default"))
            #v = super()
            #return nil if v.nil?
            #return v if v.is_a?(String)
            date.strftime("%m/%d/%Y")
          end

          define_method "#{attr}=" do |value|
            if value.blank?
              v = nil
            else
              v = Date.strptime(value, I18n.t("date.formats.default"))
            end

            super(v)

            true
          end
        end
      end
    end
  end
end