module Cms
  class RobotsController < ApplicationController
    caches_page :robots_txt

    def robots_txt
      @lines = lines
      render inline: lines.join("\r\n")
    end

    def lines
      arr = ["User-agent: *"]
      robots_txt_mode = ENV["ROBOTS_TXT_MODE"]
      robots_txt_production = robots_txt_mode == "production" || (Rails.env.production? && robots_txt_mode.blank?)
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