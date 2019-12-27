module Cms
  module Helpers
    module ImageHelper
      def self.included(base)
        methods = self.instance_methods
        methods.delete(:included)
        if base.respond_to?(:helper_method)
          base.helper_method methods
        end

      end

      # ============================================
      # --------------------------------------------
      # image helpers
      # --------------------------------------------
      # ============================================


      # http://placehold.it/300x200&text=some_text
      def stub_image_link(width = 420, height = 350, text = 'item 1')
        image_url = "http://placehold.it/#{width}x#{height}&text=#{text}"
        image_url
      end

      def stub_image(width = 420, height = 350, text = 'item 1', options = {})
        image_url = stub_image_link
        options[:src] = image_url
        output = "<img "
        options.each_pair do |key, value|
          output += "#{key}='#{value}' "
        end
        output += "/>"
        output.html_safe
      end

      def self.self_js_embedded_svg filename, options={}
        file = File.read(Rails.root.join('app', 'assets', 'images', filename))
        doc = Nokogiri::HTML::DocumentFragment.parse file
        svg = doc.at_css 'svg'
        if options[:class].present?
          svg['class'] = options[:class]
        end
        source = svg.to_html
        minimized_source = source
        minimized_source = minimized_source.remove("\r")
        minimized_source = minimized_source.remove("\t")
        minimized_source = minimized_source.remove("\n")
        minimized_source
      end

      def self.self_js_embedded_svg_string(filename, options = {})
        s = self_js_embedded_svg(filename, options)
        "'#{s}'"
      end

      def js_embedded_svg_string(filename, options = {})
        self.self_js_embedded_svg_string(filename, options)
      end

      def js_embedded_svg filename, options={}
        self.self_js_embedded_svg(filename, options)
      end

      def self.detect_svg_path(path, options = {})

        if !path.end_with?(".svg")
            path = "#{path}.svg"
        end

        if path.start_with?("/")
          return path
        else
          folders = [Rails.root.join("app/assets/images").to_s]
          folders.each do |f|
            if File.exists?(f + "/" + path)
              return f + "/" + path
            end
          end
        end

        return path
      end

      def self.self_embedded_svg_from_assets filename, options = {}
        ImageHelper.self_embedded_svg("/app/assets/images/#{filename}", options)
      end

      def embedded_svg_from_assets filename, options = {}
        ImageHelper.self_embedded_svg_from_assets(filename, options)
      end

      def inline_svg filename, options = {}
        path = Cms::Helpers::ImageHelper.detect_svg_path(filename, options)
        embedded_svg_from_absolute_path(path, options)

      end

      def embedded_svg_from_public filename, options = {}
        self.self_embedded_svg("#{filename}", options)
      end

      def self.self_embedded_svg_from_public filename, options = {}
        embedded_svg(Rails.public_path.join(filename), options)
      end

      def self.self_embedded_svg filename, options={}
        self.self_embedded_svg_from_absolute_path(Rails.root.to_s + filename.to_s, options)
      end

      def embedded_svg filename, options={}
        self.class.self_embedded_svg(filename, options)
      end

      def self.self_embedded_svg_from_absolute_path(filename, options = {})
        return nil if filename.blank?

        remove_tags = options.delete(:remove_tags)
        remove_tags = Cms.config.inline_svg_remove_tags if remove_tags.nil?
        remove_g_tags = Cms.config.inline_svg_remove_g_tags

        remove_attributes = Cms.config.inline_svg_remove_attributes
        remove_blank_tags = Cms.config.inline_svg_remove_blank_tags

        filename = filename.to_s
        filename = filename.to_s + ".svg" if filename.scan(/\.svg\Z/).empty?
        begin
          file = File.read(filename.to_s)
        rescue
          return "<svg><text>File does not exist or unreadable: '#{filename.to_s}'</text></svg>".html_safe
        end
        doc = Nokogiri::HTML::DocumentFragment.parse file
        svg = doc.at_css 'svg'
        short_attributes = [:class, :style]

        short_attributes.each do |attr|
          if options[attr].present?
            svg[attr.to_s] = options[attr]
          end
        end

        svg_width, svg_height = get_size_for_svg_by_view_box(svg['width'], svg['height'], svg['viewbox'], options)

        svg['width'] = svg_width
        svg['height'] = svg_height

        if remove_tags
          remove_tags.each do |tag_name|
            doc.search(tag_name).each do |tag|
              tag.remove
            end
          end
        end

        if remove_g_tags == :without_attributes
          doc.search('g').each do |tag|
            if tag.attributes.blank?
              tag.replace(tag.children)
            end
          end
        end

        if remove_attributes.present?
          remove_attributes.each do |item|
            doc.search(item[:tag]).each do |tag|
              item[:attributes].each do |attr|
                tag.remove_attribute(attr)
              end
            end
          end
        end

        str = doc.to_html
        str = str.gsub("\r\n", "").gsub("\t", "").gsub("\n", "")
        # remove html comments
        str = str.gsub(/\<\!\-\-[a-zA-Z0-9\.\,\s\:\-\(\)]{0,}\-\-\>/, "")

        if remove_blank_tags.present?
          remove_blank_tags.each do |tag_name|
            str = str.gsub("<#{tag_name}/>", '')
          end
        end


        #xml_start_index = str.index("<?")
        #xml_end_index = str.index("?>") + 1
        #if xml_start_index && xml_start_index >= 0
        #  str = str[xml_end_index + 1, str.length]
        #end

        svg_start = str.index("<svg")
        str = str[svg_start, str.length]

        str = str.gsub(/\>[\s]+\</, "><")

        str.html_safe
      end

      def self.compute_height_for_svg_width_by_view_box(width, viewbox)
        return nil if viewbox.blank?

        viewbox_width, viewbox_height = viewbox.split(' ')[2..3].select(&:present?).map(&:to_f)
        return nil if viewbox_width.blank? || viewbox_height.blank?
        ratio = viewbox_height.to_f / viewbox_width.to_f
        result = width.to_f * ratio.to_f
        result == result.to_i ? result.to_i : result
      end

      def self.get_size_for_svg_by_view_box(width, height, viewbox, options)
        width = width.to_f if width.present?
        height = height.to_f if height.present?

        return [width, height] if viewbox.blank?

        viewbox_width = viewbox.split(' ')[2].try(:to_f)
        viewbox_height = viewbox.split(' ')[3].try(:to_f)

        return [width, height] if viewbox_width.blank? || viewbox_height.blank?

        viewbox_ratio = viewbox_width / viewbox_height

        if width.blank? && height.blank?
          width = viewbox_width
          height = viewbox_height
        elsif width.blank?
          width = viewbox_ratio * height
        elsif height.blank?
          height = width / viewbox_ratio
        end

        if options[:width]
          width = options[:width]
          height = width / viewbox_ratio
        end

        if options[:max_width] && options[:max_width] < width
          width = options[:max_width]
          height = width / viewbox_ratio
        end

        if options[:max_height] && options[:max_height] < height
          height = options[:max_height]
          width = viewbox_ratio * height
        end

        width = width.to_i if width == width.to_i
        height = height.to_i if height == height.to_i

        [width, height]
      end

      def embedded_svg_from_absolute_path(filename, options = {})
        ImageHelper.self_embedded_svg_from_absolute_path(filename, options)
      end

      def image_or_stub_url(paperclip_instance, style = :original, width=250, height=250, text='image')
        ( (paperclip_instance && paperclip_instance.respond_to?(:exists?) && paperclip_instance.exists?(style) && paperclip_instance.respond_to?(:url) )? paperclip_instance.url(style) : stub_image_link(width, height, text) )
      end
    end
  end
end