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
  end
end