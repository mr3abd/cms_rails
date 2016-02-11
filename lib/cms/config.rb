module Cms
  module Config
    class << self
      attr_accessor :default_html_format

      def init
        self.default_html_format = :html
      end
    end
  end
end

Cms::Config.init