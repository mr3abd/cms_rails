require 'httparty'

class Cms::WeatherData < ActiveRecord::Base
  self.table_name = :weather_data

  field :result

  def self.actual(provider = :openweathermap)
    instance = self.where(provider: provider).last
    is_actual = instance.nil? || instance.created_at.blank? ? false : DateTime.now - 60.minutes < instance.created_at
    if !is_actual
      instance = self.new
      instance.send("store_#{provider}")
    end
    instance
  end

  def store_openweathermap(api_key, city = "Lviv")
    response = HTTParty.get('http://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?json', timeout: 10) rescue nil
    if response
      parsed = JSON.parse(response)
      self.result = parsed
      self.provider = "openweathermap"
    else
      []
    end
  end
end