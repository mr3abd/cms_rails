module Cms
  module Helpers
    module SiteData
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
        Hash[site_data("social_links").map{|k, v| [k, {icon: "svg/social/#{k}.svg", url: v}] }]
      end
    end
  end
end