module Cms
  module ResourceNavigation
    module InstanceMethods
      def related_articles(prev_next = true, loop = false)
        articles = self.class.published.sort_by_position
        current_index = nil
        articles.each_with_index do |a, i|
          if a[:id] == self.id
            current_index = i
            break
          end
        end

        min_index = 0
        max_index = articles.count - 1

        prev_article = nil
        next_article = nil
        if current_index
          if current_index > min_index
            prev_article = articles[current_index - 1]
          end

          if current_index < max_index
            next_article = articles[current_index + 1]
          end
        end

        {prev: prev_article, next: next_article}.select{|k, v| !v.nil? }
      end

      def prev_article
        related_articles[:prev]
      end

      def next_article
        related_articles[:next]
      end
    end

    module ClassMethods
      def has_navigation prev_next = true
        self.class_variable_set(:@@_resource_navigation, {prev_next: true})
        self.safe_include(self, Cms::ResourceNavigation::InstanceMethods)
      end
    end
  end
end

ActiveRecord::Base.send :extend, Cms::ResourceNavigation::ClassMethods


