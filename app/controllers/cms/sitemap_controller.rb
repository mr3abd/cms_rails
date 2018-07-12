module Cms
  class SitemapController < ::Cms::BaseController
    skip_all_before_action_callbacks

    if respond_to?(:caches_page)
      caches_page :index
    end

    def index
      if Cms.config.sitemap_controller.nil?
        @content = Pages.sitemap_xml.try(:content) rescue nil
        if @content.blank?
          @entries = SitemapElement.entries
        end
      else
        locales = Cms.config.sitemap_controller[:entries_for_resources][:locales]
        @entries = Cms::SitemapElement.entries_for_resources(nil, locales)
      end

    end
  end
end