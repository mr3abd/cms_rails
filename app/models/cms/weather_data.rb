require 'httparty'

class Cms::WeatherData < ActiveRecord::Base
  self.table_name = :weather_data

  field :result

  def self.actual(api_key, city = "Lviv", provider = :openweathermap)
    instance = self.where(provider: provider, locale: I18n.locale).last
    is_actual = instance.nil? || instance.created_at.blank? ? false : DateTime.now - 60.minutes < instance.created_at
    if !is_actual
      instance = self.new
      instance.send("store_#{provider}", api_key, city)
    end
    instance
  end

  def store_openweathermap(api_key, city = "Lviv")
    response = HTTParty.get("http://api.openweathermap.org/data/2.5/weather?q=#{city}&APPID=#{api_key}&units=metric&lang=#{I18n.locale}", timeout: 10) rescue nil
    if response
      parsed = JSON.parse(response.body)
      self.result = parsed
      self.provider = "openweathermap"
      self.locale = I18n.locale
    else
      []
    end
  end
end