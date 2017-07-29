module Cms
  class RobotsController < ApplicationController
    caches_page :robots_txt

    def robots_txt

    end
  end
end