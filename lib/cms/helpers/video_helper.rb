module Cms
  module Helpers
    module VideoHelper
      def self.video_url(resource)
        if (resource.try(:youtube_video_id).blank?) && (resource.try(:vimeo_video_id).blank?)
          return nil
        elsif resource.try(:youtube_video_id).present?
          return "https://www.youtube.com/watch?v=#{resource.youtube_video_id}"
        elsif resource.try(:vimeo_video_id).present?
          return "https://vimeo.com/#{resource.vimeo_video_id}"
        end
      end


      def self.frame_video_url(resource)
        if (resource.try(:youtube_video_id).blank?) && (resource.try(:vimeo_video_id).blank?)
          return nil
        elsif resource.try(:youtube_video_id).present?
          return "https://www.youtube.com/embed/#{resource.youtube_video_id}?controls=2&amp;showinfo=0&amp;autoplay=1&amp;autohide=1"
        elsif resource.try(:vimeo_video_id).present?
          return "https://player.vimeo.com/video/#{resource.vimeo_video_id}?autoplay=1"
        end
      end
    end
  end
end