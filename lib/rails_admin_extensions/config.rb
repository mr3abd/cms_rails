#puts "rails_admin: #{defined?(RailsAdmin)}"
#puts "hello"
module RailsAdmin
  module Config
    class << self
      include RailsAdmin::Config::Configurable

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

      def configure_forms(*form_classes)
        return if form_classes.blank?
        Dir[Rails.root.join("app/models/form_configs/*")].each{|s| require s }
        forms = form_classes
        if form_classes == :all
          forms = Dir[Rails.root.join("app/models/form_configs/*")].map{|s| FileUtils.base_name(s.split("/").last).camelize }
        end
        form_configs = forms.map{|c|
          if !c.is_a?(String)
            c = c.name
          end
          Object.const_get("FormConfigs::#{c}") rescue nil
        }.select{|s| !s.nil? }

        config = self

        config.include_models *form_configs
        form_configs.each do |m|
          config.model m do
            navigation_label_key(:settings)
            field :email_receivers, :text
          end
        end

        config.include_models *forms

        forms.each do |m|
          begin
            config.model m do
              navigation_label_key(:feedbacks)

              fields_method = m.respond_to?(:rails_admin_fields) ? :fields : (m.respond_to?(:fields_from_model) ? :fields_from_model : nil)
              if fields_method
                edit do
                  m.send(fields_method).each do |k|
                    field k
                  end
                end
              end
            end
          rescue

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

      register_instance_option :navigation_labels do
        {}
      end

    end
  end
end