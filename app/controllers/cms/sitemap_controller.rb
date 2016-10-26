module Cms
  class SitemapController < ApplicationController
    caches_page :index
    def index
      @content = Pages.sitemap_xml.try(:content) rescue nil
      if @content.blank?
        @entries = SitemapElement.entries
      end
    end
  end
end