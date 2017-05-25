module Cms
  module Helpers
    module SocialHelper
      def self.get_share_links(object = nil, url = nil, title = nil, keys = nil)
        if object
          url = Rails.application.routes.url_helpers.url_for(object) if url.blank?
          title = object.try(:title) if title.blank?
          title = object.try(:name) if title.blank?
        elsif url.blank? || title.blank?
          raise StandardError, "Setting#get_share_links: please provide url and title"
        end
        host = Rails.application.config.action_mailer.default_url_options[:host]
        full_url = "#{host}#{url}"
        #settings = self.first
        result = {}
        keys ||= [:facebook, :vk, :twitter]
        keys.each do |field_name|
          value = self.send("get_#{field_name}_share_link", full_url, title)
          if value && value.length > 0
            result[field_name] = value
          end
        end

        result
      end

      def self.get_facebook_share_link(url, title)
        "http://www.facebook.com/sharer/sharer.php?u=#{url}&title=#{title}"
      end

      def self.get_twitter_share_link(url, title)
        "http://twitter.com/intent/tweet?status=#{title}+#{url}"
      end

      def self.get_linked_in_share_link(url, title)
        "http://www.linkedin.com/shareArticle?mini=true&url=#{url}&title=#{title}&source=[SOURCE/DOMAIN]"
      end

      def self.get_vk_share_link(url, title = nil)
        "http://vk.com/share.php?url=#{url}"
      end

      def self.get_google_plus_share_link(url, title = nil)
        "https://plus.google.com/share?url=#{url}"
      end
    end
  end
end
