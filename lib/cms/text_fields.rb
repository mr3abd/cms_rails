module Cms
  module TextFields
    def line_separated_field=(key, val)
      key = key.to_s
      if val.is_a?(Array)
        val = val.join("\r\n")
      end

      self[key] = val

      true
    end

    def self.get_line_separated_field_value(resource, key, parse = true)
      key = key.to_s
      val = resource[key]
      if parse
        if val.blank?
          return []
        end
        return val.split("\r\n")
      else
        return val
      end
    end

    def line_separated_field(key, parse = true)
      Cms::TextFields.get_line_separated_field_value(self, key, parse)
    end

    def properties_field(db_column, locale = I18n.locale, keep_empty_values = false)
      properties_str = self.class.globalize_attributes.map(&:to_s).include?(db_column.to_s) ? self.translations_by_locale[locale].try(db_column) : self[db_column]
      if properties_str.blank?
        return {}
      end
      lines = properties_str.split("\r\n")
      props = Hash[lines.map{|line|
        i = line.index(":")
        if 1 == 1
          if !keep_empty_values && (i.nil? || i < 0)
            next nil
          end
        end



        k = line[0, i || line.length]
        if i
          v = line[i+1, line.length]
        else
          v = ""
        end

        [k, v]
      }.select(&:present?)]

      props
    end
  end
end