Configurable = RailsAdmin::Config::Configurable

module Cms
  class Config
    include Configurable

    register_class_option :default_html_format do
      :html
    end

    register_class_option :use_translations do
      ActiveRecord::Base.respond_to?(:translates?) && Cms.config.provided_locales.count > 1
    end

    register_class_option :provided_locales do
      I18n.available_locales
    end

    register_class_option :clear_cache_for_locales do
      [I18n.locale]
    end

    register_class_option :locale_names do
      {
          ru: "рус",
          uk: "укр",
          en: "eng",
          fr: "fra",
          es: "esp"
      }
    end

    register_class_option :exchange_rate_class do
      false
    end

    register_class_option :weather_data_class do
      false
    end

    register_class_option :file_editor_use_can_can do
      false
    end

    register_class_option :default_sitemap_priority do
      0.9
    end

    register_class_option :default_sitemap_change_freq do
      :monthly
    end

    register_class_option :sitemap_controller do
      nil
    end



    [:banner, :form_config, :html_block, :content_block, :meta_tags, :page, :sitemap_element].each do |model_name|
      register_class_option "#{model_name}_class" do

        model_class_name = "Cms::#{model_name.to_s.camelize}"
        #if Object.const_defined?(model_class_name)

        #end

        Object.const_get(model_class_name)

      end
    end
  end
end

#Cms::Config.init