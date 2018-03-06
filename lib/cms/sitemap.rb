module Cms
  module Sitemap
    module ClassMethods

    end

    module InstanceMethods
      def sitemap_image(attachment_name = :image, style_name = :original)

        #attachment = self.try(attachment_name)
        #if !attachment || !attachment.exists?(style_name)
        #  return
        #end

        image_url = attachment.url(style_name)
        image_alt = attachment.try("#{attachment_name}_seo_alt")
        image_title = attachment.try("#{attachment_name}_seo_title")



        h = {}
        h[:url] = image_url
        h[:alt] = image_alt if image_alt.present?
        h[:title] = image_title if image_title.present?

        h
      end

      def get_sitemap_images
        @_sitemap_record_images ||= []
      end
    end
  end
end