module Cms
  module FormAttributesHelper
    def form_attributes(with_associations = false)
      columns = self.attribute_names.map{|k|
        ignored_attributes = ["id"]
        next nil if k.in?(ignored_attributes)
        if k.ends_with?("_content_type") || k.ends_with?("_file_name") || k.ends_with?("_file_size") || k.ends_with?("_updated_at")
          if k.ends_with?("_content_type")
            next k[0..k.length-14]
          else
            next nil
          end
        end

        if with_associations
          if k.ends_with?("_id")
            reflection_name = k[0..k.length - 4]
            if self._reflections.keys.include?(reflection_name)
              next reflection_name
            end
          end

          next k
        end

        next k
      }.select(&:present?).uniq.map(&:to_sym)
    end
  end
end