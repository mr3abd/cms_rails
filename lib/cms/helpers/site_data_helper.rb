module Cms
  module Helpers
    module SiteDataHelper
      def self.included(base)
        methods = [:site_data, :social_links]
        if base.respond_to?(:helper_method)
          base.helper_method methods
        end

      end

      def site_data(k)
        begin
          h = YAML.load(IO.read(Rails.root.join("config/site_data.yml").to_s))['site_data']
          keys = k.split(".")
          v = h
          keys.each do |k|
            v = v[k]
          end
          return v

        rescue
          return nil
        end
      end

      def social_links
        Hash[site_data("social_links").map{|k, v| next nil if v.blank?; [k, {icon: "svg/social/#{k}.svg", url: v}] }.select(&:present?)]
      end
    end
  end
end