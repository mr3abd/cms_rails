module Cms
  module Helpers
    module MetaDataHelper
      def self.included(base)
        methods = self.instance_methods
        methods.delete(:included)
        if base.respond_to?(:helper_method)
          base.helper_method methods
        end

      end

      def head_title
        title = @head_title

        title = @page_metadata.try do |m|
          if m.is_a?(Hash)
            break m[:head_title]
          else
            break m.title
          end
        end if title.blank?


        title = (@page || @resource).try{|p| p.seo_tags.try(&:title) if p.respond_to?(:seo_tags) } if title.blank?
        title = (@resource).try{|m| m.title if m.respond_to?(:title); m.meta_title if m.respond_to?(:meta_title) } if title.blank?
        title = @resource.try{|r|  } if title.blank?
        title = (Cms.t("head_title_untitled", raise: true) rescue "#{controller_name}##{action_name}")  if title.blank?
        #raw Cms.t("head_title", title: title)
        title = title.gsub(/\</, "&lt;").gsub(/\>/, "&gt;").gsub(/\s\Z/, "").gsub(/\A\s/, "").gsub(/\s\Z/, "")
        title_with_template = t("head_title_template", raise: true, title: title) rescue nil
        if title_with_template.present?
          return title_with_template
        end
        title
      end

      def meta_keywords
        keywords = @meta_keywords
        keywords = (@page || @resource).try{|p| p.seo_tags.try(&:keywords) if p.respond_to?(:seo_tags) } if keywords.blank?
        keywords = (@page_metadata || @resource).try{|m| next m.keywords if m.respond_to?(:keywords); next m.meta_keywords if m.respond_to?(:meta_keywords) } if keywords.blank?
        keywords = "" if keywords.blank?
        keywords = keywords.gsub(/\"/, "&quot;").gsub(/\s\Z/, "").gsub(/\A\s/, "").gsub(/\s\Z/, "")
        keywords
      end

      def meta_description
        description = @meta_description
        description = (@page || @resource).try{|p| p.seo_tags.try(&:description) if p.respond_to?(:seo_tags) } if description.blank?
        description = @page_metadata.try{|m| m.description if m.respond_to?(:description) } if description.blank?
        description = @resource.try{|m| next m.meta_description if m.respond_to?(:description); next m.meta_description if m.respond_to?(:meta_description) } if description.blank?
        description = @resource.try(:description) if description.blank?
        description = '' if description.blank?
        description = description.gsub(/\"/, "&quot;").gsub(/\s\Z/, "").gsub(/\A\s/, "").gsub(/\s\Z/, "")
        description
      end

      def meta_robots_tag
        page = (@page || @resource || @page_instance)
        h = {}
        h[:noindex] = @noindex
        h[:noindex] = page.noindex? if h[:noindex].nil? && page.respond_to?(:noindex?)
        h[:noindex] ||= false

        h[:nofollow] = @nofollow
        h[:nofollow] = page.nofollow? if h[:nofollow].nil? && page.respond_to?(:nofollow?)
        h[:nofollow] ||= false

        str = h.map{|k, v| v == true ? k.to_s : nil }.select(&:present?).join(",")
        if str.blank?
          return ""
        end
        meta_tag("robots", str)
      end

      def og_image
        absolute_url(@og_image) rescue nil
      end

      def og_video
        @og_video
      end

      def og_type
        @og_type
      end

      def og_title
        s = @og_title
        s.present? ? s : head_title
      end

      def og_description
        s = @og_description
        s.present? ? s : meta_description
      end

      def render_og_tags
        result = ""
        result += meta_tag("og:title", og_title)
        result += meta_tag("og:description", og_description)


        result += meta_tag("og:image", og_image)

        result += meta_tag("og:type", og_type)


        if og_video.present?
          if og_video.is_a?(String)
            result += meta_tag("og:video", og_video)
          elsif og_video.is_a?(Hash)
            og_video.each do |k, v|
              result += meta_tag("og:video:#{k}", v)
            end
          elsif og_video.is_a?(Array)
            og_video.each do |item|
              k = item.first
              v = item.second
              result += meta_tag("og:video:#{k}", v)
            end
          end
        end



        result
      end

      def meta_tag(name, content)
        return "" if name.blank? || content.blank?
        (content_tag(:meta, nil, content: raw(content), name: name))
      end

      def link_tag(rel, attrs = {})
        return "" if rel.blank? || attrs.blank?
        h = attrs
        h[:rel] = rel
        (content_tag(:link, nil, h))
      end

      def seo_tags
        result = ""
        if respond_to?(:locale_links)
          locale_links = self.locale_links
          if locale_links.present? && locale_links.keys.count > 1
            locale_links.each do |locale, url|
              result += link_tag("alternate", href: absolute_url(url), hreflang: locale)
            end
          end
        end

        if (title = head_title).present?
          result += (content_tag(:title, raw(title)))
        end



        result += meta_robots_tag
        result += meta_tag("description", meta_description)



        result += meta_tag("keywords", meta_keywords)


        result += render_og_tags



        result.html_safe
      end
    end
  end
end