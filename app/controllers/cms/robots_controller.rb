module Cms
  class RobotsController < ApplicationController
    caches_page :robots_txt

    def robots_txt
      render "robots.txt"
    end
  end
end