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

    [:banner, :form_config, :html_block, :meta_tags, :page, :sitemap_element].each do |model_name|
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