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

    def line_separated_field(key, parse = true)
      key = key.to_s
      val = self[key]
      if parse
        if val.blank?
          return []
        end
        return val.split("\r\n")
      else
        return val
      end
    end

    def properties_field(db_column, locale = I18n.locale)
      properties_str = self.class.globalize_attributes.map(&:to_s).include?(db_column.to_s) ? self.translations_by_locale[locale].try(db_column) : self[db_column]
      if properties_str.blank?
        return {}
      end
      lines = properties_str.split("\r\n")
      props = Hash[lines.map{|line|
        i = line.index(":")
        if i < 0
          next nil
        end

        k = line[0, i]
        v = line[i+1, line.length]
        [k, v]
      }.select(&:present?)]

      props
    end
  end
end