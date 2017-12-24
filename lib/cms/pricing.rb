module Cms
  module Pricing
    def price_for(name, currency = nil)
      send("#{name}_value")
    end
  end
end