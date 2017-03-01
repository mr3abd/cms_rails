module Cms
  module Helpers
    module PaginationHelper
      def self.items_per_page
        9
      end

      def get_paginated_entries(entries, items_per_page = nil)
        max_items_count = items_per_page || PaginationHelper.items_per_page
        params_page = params[:page].present? ? params[:page] : nil
        if !params_page
          list_page = 1
        else
          list_page = params_page
        end

        entries.paginate(page: list_page, per_page: max_items_count)
      end

      def filter_by_tags(collection, tags = @selected_tags_url_fragments)
        if tags.blank?
          return collection
        end

        collection.joins(tags: :translations).where(cms_tag_translations: {url_fragment: tags, locale: I18n.locale} ).uniq
      end

      def self.tags_url_fragment(tag, selected_tags = [])

        tags_arr = [tag, *selected_tags]
        processed_tags_arr = tags_arr.map{|tag| next tag if tag.is_a?(String) || tag.nil?; tag.url_fragment }.select(&:present?).uniq
        processed_tags_arr = processed_tags_arr.select{|t| tag.nil? || t != tag.url_fragment || !t.in?(selected_tags) }
        if processed_tags_arr.blank?
          return nil
        end
        tags_str = processed_tags_arr.join(",")
        tags_part_str = "tags=#{tags_str}"
      end
    end
  end
end