module Cms
  module Helpers
    module PrettyCount
      def pretty_count(number, i18n_key_path)
        last_number = number % 10
        if last_number == 1
          key = "one"
        elsif last_number >= 2 && last_number <= 4
          key = "few"
        else
          key = "other"
        end

        str = I18n.t("#{i18n_key_path}.#{key}", raise: true) rescue nil
        if str.blank?
          str = I18n.t("#{i18n_key_path}", raise: true)
          if str.is_a?(String)
            return str
          else
            return "translation missing: #{i18n_key_path}.#{key}, #{i18n_key_path}"
          end
        else
          return str
        end
      end

      class Methods
        extend PrettyCount
      end
    end
  end
end