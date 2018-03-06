module Cms
  module Sitemap
    module ClassMethods

    end

    module InstanceMethods
      def sitemap_image(attachment_name = :image, style_name = :original)

        @_sitemap_record_images ||= []

        attachment = self.try(attachment_name)

        if !attachment || !attachment.exists?(style_name)
          return
        end

        image_url = attachment.url(style_name)
        #image_alt = attachment.try("#{attachment_name}_seo_alt")
        #image_title = attachment.try("#{attachment_name}_seo_title")



        h = {}
        h[:url] = image_url
        #if image_alt.present? || image_title.present?
        I18n.available_locales.each do |locale|
          image_alt = attachment.translations_by_locale[locale].try("#{attachment_name}_seo_alt")
          image_title = attachment.translations_by_locale[locale].try("#{attachment_name}_seo_title")

          if image_alt.present? || image_title.present?
            h[:translations] ||= {}
            h[:translations][locale.to_sym] ||= {}
            h[:translations][locale.to_sym][:alt] = image_alt if image_alt.present?
            h[:translations][locale.to_sym][:title] = image_title if image_title.present?
          end
        end
        #end

        @_sitemap_record_images << h

        h
      end

      def get_sitemap_images
        record_method = (self.class.class_variable_get(:@@_cache_method) rescue nil) || nil
        if record_method
          instance_eval(record_method)
        end
        @_sitemap_record_images ||= []
      end
    end
  end
end