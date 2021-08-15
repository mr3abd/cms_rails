module Cms
  module TextFields
    def line_separated_field=(key, val, options = {})
      key = key.to_s
      if val.is_a?(Array)
        separator = options[:group_lines] ? "\r\n\r\n" : "\r\n"
        val = val.join(separator)
      end

      self[key] = val

      true
    end

    def self.get_line_separated_field_value(resource, key, parse = true, options = {})
      group_lines = options[:group_lines]
      key = key.to_s
      val = resource[key]
      if parse
        if val.blank?
          return []
        end
      else
        return val
      end

      lines = val.split("\r\n")

      return lines unless group_lines

      groups = []
      group_index = 0
      lines.each do |line|
        if line.blank?
          if groups[group_index].present?
            group_index += 1
          end

          next
        end

        groups[group_index] ||= []
        groups[group_index] << line
      end

      groups
    end

    def line_separated_field(key, parse = true, options = {})
      Cms::TextFields.get_line_separated_field_value(self, key, parse, options)
    end

    def properties_field(db_column, locale = I18n.locale, keep_empty_values = false)
      if self.class.respond_to?(:globalize_attributes) && self.class.globalize_attributes.map(&:to_s).include?(db_column.to_s)
        properties_str = self.translations_by_locale[locale].try(db_column)
      else
        properties_str = self[db_column]
      end

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