module Cms
  module Helpers
    module DateHelper
      module ClassMethods
        def self.date_field(attr)
          define_method "#{attr}" do
            v = super()
            return nil if v.nil?
            v.strftime("%m/%d/%Y")
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