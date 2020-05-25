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
        if v.scan(/\A\+\d/).blank? && !v.start_with?('0800')
          v = "+#{country_code}#{v}"
        end

        v = v.gsub(/\s/, "")

        "tel:#{v}"
      end

      def email_url(email)
        "mailto:#{email.downcase}"
      end

      def absolute_url(url)
        if url.present?
          if url.start_with?("/") && !url.start_with?("//")
            host = ENV["#{Rails.env}.host_with_port"].presence || (ENV["dns.schema"] || "http") + "://" + (ENV["dns.domain"] || ENV["#{Rails.env}.host"] )
            url = host + url
          end
        end

        url
      end

      def self.helper
        Helper
      end

      class Helper
        extend ::Cms::Helpers::UrlHelper
      end

    end
  end
end
