module Cms
  class GoogleController < ApplicationController
    caches_page :web_master
    def web_master
      render inline: "google-site-verification: google#{ENV["GOOGLE_WEB_MASTER_ID"]}.html"
    end
  end
end