module Cms
  module Helpers
    module AssetHelper
      def self.included(base)
        methods = [:inline_css, :inline_js]
        if base.respond_to?(:helper_method)
          base.helper_method methods
        end
      end

      def asset_to_string(name)
        app = Rails.application
        if Rails.configuration.assets.compile
          app.assets.find_asset(name).to_s
        else
          controller.view_context.render(file: File.join('public/assets', app.assets_manifest.assets[name]))
        end
      end

      def inline_css(name, minify: true)
        extensions = ["css", "scss", "sass"]
        name = extensions.any?{|s| name.end_with?(".#{s}") } ? name : "#{name}.css"
        str = asset_to_string(name)
        str = minify_css(str) if minify

        if str.present?
          "<style>#{str}</style>".html_safe
        else
          ""
        end
      end

      def inline_js(*names)
        str = ''

        names.map do |name|
          extensions = ["js", "coffee"]
          name = extensions.any?{|s| name.end_with?(".#{s}") } ? name : "#{name}.js"

          s = (asset_to_string(name))
          if s.present?
            if str.present? && !str.end_with?(';')
              str += ';'
            end

            str += s
          end
        end

        if str.present?
          "<script type='text/javascript'>#{str}</script>".html_safe
        else
          ""
        end
      end

      def self.minify_css(str)
        #str.gsub(/\/\*[\sa-zA-Z0-9\/\,\.]{0,}\*\//, "")
        #Uglifier.new.compile(str)

        str = remove_css_comments(str)

        #str
        str.gsub(/\/\*[\sa-zA-Z\_0-9\,\/\.]{0,}\*\//, "").gsub(/\s\{/, "{").gsub(/\}[\s]{1,}/, "}").gsub(/\;[\s]+/, ";").gsub(/[\s]+\;/, ";").gsub(/\{\s/, "{").gsub(/\;\s/, ";").gsub(/\A\s/, "").gsub(/\s\Z/, "").gsub(/\A\s?\Z/, "")
            .gsub(/\{[\s]{1,}/, "{").gsub(", ", ",").gsub("\n", "").gsub("; ", ";").gsub(": ", ":").gsub(/\}[\s]{1,}/, "}").gsub(";}", "}")
      end

      def self.remove_css_comments(str)
        # while str.index('//')
        #
        # end

        while str.index('/*') && str.index('*/')
          start_index = str.index('/*')
          end_index = str.index('*/')
          new_str = ''
          if start_index > 0
            new_str = str[0...start_index]
          end

          if end_index < str.length - 1
            new_str += str[end_index+1...str.length]
          end

          str = new_str
        end

        str
      end

      def minify_css(str)
        Cms::Helpers::AssetHelper.minify_css(str)
      end

      def minify_js(str)
        str
      end
    end
  end
end
