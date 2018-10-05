module Cms
  class RobotsController < ::Cms::BaseController
    if respond_to?(:caches_page)
      caches_page :robots_txt
    end

    def robots_txt
      @lines = lines
      render inline: lines.join("\r\n")
    end

    def lines
      arr = []
      robots_txt_mode = ENV["ROBOTS_TXT_MODE"]
      robots_txt_production = robots_txt_mode == "production" || (Rails.env.production? && robots_txt_mode.blank?)

      if robots_txt_production && ENV["ROBOTS_TXT_DISABLE_WEB_ARCHIVE"].to_s != 'false'
        arr << 'User-agent: ia_archiver'
        arr << 'Disallow: /'
        arr << ''
      end

      arr << "User-agent: *"
      if robots_txt_production
        arr << "Disallow: "
      else
        arr << "Disallow: /"
      end
      if robots_txt_production
        arr << "Sitemap: #{absolute_url("/sitemap.xml")}"
      end

      arr
    end


  end
end