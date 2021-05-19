module Cms
  class FacebookController < ::Cms::BaseController
    if respond_to?(:caches_page)
      caches_page :verification
    end

    def verification
      render inline: ENV["FACEBOOK_VERIFICATION_ID"]
    end
  end
end
