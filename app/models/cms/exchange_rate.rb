require 'httparty'

class Cms::ExchangeRate < ActiveRecord::Base
  self.table_name = :exchange_rates
  field :result

  def self.actual(provider = :nbu)
    instance = self.last
    is_actual = instance.nil? || instance.created_at.blank? ? false : DateTime.now - 24.hours < instance.created_at
    if !is_actual
      instance = self.new
      instance.send("store_#{provider}")
    end
    instance
  end

  def store_nbu
    response_nbu = HTTParty.get('http://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?json', timeout: 10) rescue nil
    if response_nbu
      data_nbu = JSON.parse(response_nbu.body)
      #usd_nbu = data_nbu.select {|key| key["r030"] == 840 }
      #eur_nbu = data_nbu.select {|key| key["r030"] == 978 }
      self.result = data_nbu
      self.provider = :nbu
    else
      []
    end

  end

  def store_private_bank
    response_private = HTTParty.get('https://api.privatbank.ua/p24api/pubinfo?json&exchange&coursid=5')
    if response_private
      data_private = JSON.parse(response_private.body)
      #usd_private = data_private.select {|key| key["ccy"] == "USD" }
      #eur_private = data_private.select {|key| key["ccy"] == "EUR" }
      self.provider = "private_bank"
      self.result = data_private
    else
      []
    end
  end

  def convert(amount = 1, input_currency = :usd, output_currency = :uah, direction = :sale)
    if self.provider.to_sym == :private_bank
      item = result.select{|item| item['ccy'] == input_currency.upcase && item['base_ccy'] == output_currency.upcase  }.first
      if !item
        return nil
      end

      amount * item[direction.to_s].to_f
    end
  end
end