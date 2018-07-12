module Cms
  class GoogleController < ::Cms::BaseController
    if respond_to?(:caches_page)
      caches_page :web_master
    end

    def web_master
      render inline: "google-site-verification: google#{ENV["GOOGLE_WEB_MASTER_ID"]}.html"
    end
  end
end