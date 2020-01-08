module Cms
  class YandexController < ::Cms::BaseController
    if respond_to?(:caches_page)
      caches_page :verification
    end

    def verification
      head = '<head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"></head>'
      body = "<body>Verification: #{ENV["YANDEX_VERIFICATION_ID"]}</body>"

      render inline: "<html>#{head}#{body}</html>"
    end
  end
end