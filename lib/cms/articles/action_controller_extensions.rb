module Cms
  module Articles
    module ActionControllerExtensions
      module ClassMethods
        def tracks_articles

        end
      end
    end
  end
end

ActionController::Base.send(:extend, Cms::Articles::ActionControllerExtensions::ClassMethods)