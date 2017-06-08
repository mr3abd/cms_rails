module Cms
  module FormAttributesHelper
    def form_attributes
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

        next k
      }.select(&:present?).map(&:to_sym)
    end
  end
end