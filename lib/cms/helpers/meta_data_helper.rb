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


        title = (@page || @resource || @page_instance).try{|p| p.seo_tags.try(&:title) if p.respond_to?(:seo_tags) } if title.blank?
        title = (@resource).try{|m| m.title if m.respond_to?(:title); m.meta_title if m.respond_to?(:meta_title) } if title.blank?
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
        description = (@resource || @page_instance || @page).try(:description) if description.blank?
        description = (@page_instance || @page || @resource).try(:short_description) if description.blank?
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
        image_url = @og_image || @default_og_image
        return nil if image_url.blank?
        absolute_url(image_url) rescue nil
      end

      def og_video
        @og_video
      end

      def og_type
        @og_type || 'website'
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
        result += meta_tag("og:title", og_title, :property)
        result += meta_tag("og:description", og_description, :property)


        result += meta_tag("og:image", og_image, :property)

        result += meta_tag("og:type", og_type, :property)


        if og_video.present?
          if og_video.is_a?(String)
            result += meta_tag("og:video", og_video, :property)
          elsif og_video.is_a?(Hash)
            og_video.each do |k, v|
              result += meta_tag("og:video:#{k}", v, :property)
            end
          elsif og_video.is_a?(Array)
            og_video.each do |item|
              k = item.first
              v = item.second
              result += meta_tag("og:video:#{k}", v, :property)
            end
          end
        end



        result
      end

      def render_pinterest_tags
        if (p_domain_verification_id = ENV["PINTEREST_DOMAIN_VERIFICATION_ID"]).present? && Rails.env.production?
          meta_tag("p:domain_verify", p_domain_verification_id)
        else
          ""
        end
      end

      def meta_tag(name, content, name_attribute = :name)
        return "" if name.blank? || content.blank?
        (content_tag(:meta, nil, content: raw(content), "#{name_attribute}": name))
      end

      def link_tag(rel, attrs = {})
        return "" if rel.blank? || attrs.blank?
        h = attrs
        h[:rel] = rel
        # h = h.keep_if do |k, v|
        #   !v.nil?
        # end
        h.each do |k, v|
          h[k] = "" if v.nil?
        end
        (content_tag(:link, nil, h)) rescue ""
      end

      def canonical_link
        url = @page_instance.try(:url)
        return nil if url.blank?
        abs_url = absolute_url(url)

        link_tag('canonical', href: abs_url)
      end

      def seo_tags
        result = ""
        if respond_to?(:locale_links)
          begin
            locale_links = self.locale_links
            if locale_links.present? && locale_links.keys.count > 1
              locale_links.each do |locale, url|
                abs_url = absolute_url(url)
                if abs_url.nil?
                  next
                end
                result += link_tag("alternate", href: abs_url, hreflang: locale)
              end
            end
          rescue

          end
        end

        if (title = head_title).present?
          result += (content_tag(:title, raw(title)))
        end

        result += meta_robots_tag

        result += meta_tag("description", meta_description)

        result += meta_tag("keywords", meta_keywords)

        result += render_og_tags

        result += render_pinterest_tags

        result.html_safe
      end

      def seo_image(resource, image_url, attachment_name = :image)

        h = {class: "seo"}
        h[:src] = image_url
        image_alt = seo_image_alt(resource, attachment_name)
        image_title = seo_image_title(resource, attachment_name)

        if image_alt.present?
          h[:alt] = image_alt
        end

        if image_title.present?
          h[:title] = image_title
        end

        content_tag(:img, nil, h)
      end

      def seo_image_title(resource, attachment_name = :image)
        image_title = resource.try("#{attachment_name}_seo_title")
        if image_title.present?
          return image_title
        elsif (image_alt = resource.try("#{attachment_name}_seo_alt")).present?
          return image_alt
        elsif (resource_name = resource.try(:name)).present?
          return resource_name
        elsif (resource_title = resource.try(:title)).present?
          return resource_title
        else
          return nil
        end
      end

      def seo_image_alt(resource, attachment_name = :image)
        image_alt = resource.try("#{attachment_name}_seo_alt")
        if image_alt.present?
          return image_alt
        elsif (image_title = resource.try("#{attachment_name}_seo_title")).present?
          return image_title
        elsif (resource_name = resource.try(:name)).present?
          return resource_name
        elsif (resource_title = resource.try(:title)).present?
          return resource_title
        else
          return nil
        end
      end

      def _render_json_ld_tag(entry)
        return "" if entry.blank?

        "<script type='application/ld+json'>#{entry.to_json}</script>"
      end

      def json_ld(keys = nil)
        s = ""
        @micro_data ||= {}

        @micro_data[:breadcrumbs] = _render_breadcrumbs_hash

        if @micro_data.blank?
          return s
        end

        if keys.nil?
          keys = @micro_data.keys.map(&:to_sym)
        else
          keys = keys.select{|k| (k.is_a?(String) || k.is_a?(Symbol)) && k.to_s.present? }.map(&:to_sym)
        end


        keys.each do |k|
          entry = @micro_data[k]
          next if entry.blank?
          s += _render_json_ld_tag(entry)
        end

        s.html_safe
      end

      def _render_breadcrumbs_hash
        return nil if @_breadcrumbs.blank?
        blank_breadcrumb_found = false

        entries = @_breadcrumbs.map.with_index do |b, breadcrumb_index|
          next if blank_breadcrumb_found

          if b[:url].blank? || b[:name].blank?
            blank_breadcrumb_found = true
            next
          end

          {
            "@type": "ListItem",
            "position": breadcrumb_index + 1,
            "item": {
              "@id": Cms::Helpers::UrlHelper.helper.absolute_url(b[:url]),
              "name": b[:name]
            }
          }
        end.select(&:present?)

        return nil if entries.blank?

        data = {
          "@context": "http://schema.org",
          "@type": "BreadcrumbList",
          "itemListElement": entries
        }

        data
      end
    end
  end
end