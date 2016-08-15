class Cms::WeatherData < ActiveRecord::Base
  self.table_name = :weather_data

  field :result

  def self.actual(provider = :nbu)
    instance = self.where(provider: provider).last
    is_actual = instance.nil? || instance.created_at.blank? ? false : DateTime.now - 24.hours < instance.created_at
    if !is_actual
      instance = self.new
      instance.send("store_#{provider}")
    end
    instance
  end

  def store_openweathermap(api_key, city = "Lviv")

  end
end