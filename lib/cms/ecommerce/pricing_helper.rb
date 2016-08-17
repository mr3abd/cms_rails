module Cms
  module ECommerce
    module Helpers
      module PricingHelper
        def format_price(price)
          parsed = price.to_f
          s = parsed.round(2).to_s
          parts = s.split(".")
          if parts.last.length == 1
            s += "0"
          end

          formatted_parts = s.split(".")
          kop = ""
          kop = "<span class='kop'>.#{formatted_parts.last}</span>" if formatted_parts.last

          "#{formatted_parts.first}#{kop}".html_safe
        end
      end
    end
  end
end