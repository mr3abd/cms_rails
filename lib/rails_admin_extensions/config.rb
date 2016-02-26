#puts "rails_admin: #{defined?(RailsAdmin)}"
#puts "hello"
module RailsAdmin
  module Config
    class << self
      def include_pages_models()
        include_models(*Cms.pages_models)
      end

      def include_templates_models(config)
        include_models(*Cms.templates_models)
      end

      def include_models(*models)
        c = self # config
        models.each do |model|
          c.included_models += [model]

          if !model.instance_of?(Class)
            Dir[Rails.root.join("app/models/#{model.underscore}")].each do |file_name|
              require file_name
            end

            model = model.constantize rescue nil
          end

          if model.respond_to?(:translates?) && model.translates?
            c.included_models += [model.translation_class]
          end
        end
      end

      def configure_cms
        Cms.configure_rails_admin(self)
      end


    end
  end
end