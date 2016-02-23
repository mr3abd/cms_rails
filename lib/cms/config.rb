module Cms
  module Config
    class << self
      attr_accessor :default_html_format
      attr_accessor :use_translations

      def init
        self.default_html_format = :html
        self.use_translations = ActiveRecord::Base.respond_to?(:translates?)
      end
    end
  end
end

Cms::Config.init