module Cms
  module Helpers
    module TranslationHelper
      def t(*args)
        @t_page_classes ||= Hash[Pages.all_instances.select{|c| c.try(:page_info).present? }.map{|p| c = p.class; pic = c.page_info_class; [c.name.split("::").last.underscore, {attribute_names: pic.attribute_names, page_info: p.page_info, page: p}] }] rescue nil
        res = nil
        if @t_page_classes.try(:any?)
          args.take_while{|a| a.is_a?(String) || a.is_a?(Symbol) }.each do |str|
            key_parts = str.split(".")
            if key_parts.length == 2 && (page_hash = @t_page_classes[key_parts.first]) && page_hash[:attribute_names].include?(key_parts[1])
              res = page_hash[:page].try(key_parts[1])
              res = page_hash[:page_info].try(key_parts[1]) if res.blank?
            end

            return res if res.present?
          end
        end
        Cms.t(*args)
      end
    end
  end
end
