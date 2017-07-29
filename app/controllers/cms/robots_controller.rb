module Cms
  class RobotsController < ApplicationController
    caches_page :robots_txt

    def robots_txt
      @lines = lines
      render inline: lines.join("\r\n")
    end

    def lines
      arr = ["User-agent: *"]
      if Rails.env.production?
        arr << "Allow: /"
      else
        arr << "Disallow: /"
      end
      arr << "Sitemap: #{absolute_url("/sitemap.xml")}"
      arr
    end


  end
end