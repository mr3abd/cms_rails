module Cms
  module Helpers
    module UrlHelper
      def self.included(base)
        methods = self.instance_methods
        methods.delete(:included)
        if base.respond_to?(:helper_method)
          base.helper_method methods
        end

      end

      def phone_url(phone)
        country_code = "38"
        v = phone.gsub(/\s/, "").gsub(/\(/, '').gsub(/\)/, '').gsub(/\-/, '').gsub(/\s/, "")
        if v.scan(/\A\+\d/).blank?
          v = "+#{country_code}#{v}"
        end

        v = v.gsub(/\s/, "")

        "tel:#{v}"
      end

      def email_url(email)
        "mailto:#{email}"
      end

    end
  end
end
