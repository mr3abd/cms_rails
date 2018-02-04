module Cms
  module Helpers
    module VideoHelper
      def self.video_url(resource)
        video_provider = self.video_provider(resource)
        if !video_provider
          return nil
        elsif video_provider == :youtube
          return "https://www.youtube.com/watch?v=#{resource.youtube_video_id}"
        elsif video_provider == :vimeo
          return "https://vimeo.com/#{resource.vimeo_video_id}"
        end
      end


      def self.frame_video_url(resource)
        video_provider = self.video_provider(resource)
        if !video_provider
          return nil
        elsif video_provider == :youtube
          return "https://www.youtube.com/embed/#{resource.youtube_video_id}?controls=2&amp;showinfo=0&amp;autoplay=1&amp;autohide=1"
        elsif video_provider == :vimeo
          return "https://player.vimeo.com/video/#{resource.vimeo_video_id}?autoplay=1"
        end
      end

      def self.video_provider(resource)
        if resource.try(:youtube_video_id).present?
          :youtube
        elsif resource.try(:vimeo_video_id).present?
          :vimeo
        else
          nil
        end
      end
    end
  end
end