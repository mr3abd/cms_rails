#puts "rails_admin: #{defined?(RailsAdmin)}"
#puts "hello"
module RailsAdmin
  module Config
    register_class_option :navigation_labels do
      {}
    end

    class << self
      def include_pages_models()
        include_models(*Cms.pages_models)
      end

      def include_templates_models(config)
        include_models(*Cms.templates_models)
      end

      def resolve_translation_class(model)
        if !model
          return nil
        end
        translation_class_name = "#{model.name}::Translation"
        if !Object.const_defined?(translation_class_name)
          return nil
        end

        return translation_class_name

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

          #if model.respond_to?(:translates?) && model.translates?
          #if model.respond_to?(:translates?) && model.translates? && model.respond_to?(:translation_class)
          translation_class_name = resolve_translation_class(model)
          if translation_class_name
            c.included_models += [translation_class_name]
          end
        end
      end

      def model_translation(model, &block)
        translation_class_name = resolve_translation_class(model)
        #if model.respond_to?(:translation_class)
        if translation_class_name
          #self.model(model.translation_class, &block)
          self.model translation_class_name do
            visible false
            self.instance_eval(&block)
          end
        end
      end

      def configure_cms
        Cms.configure_rails_admin(self)
      end



    end
  end
end