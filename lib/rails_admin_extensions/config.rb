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

      def resolve_translation_class(model, return_class_or_name = :name)
        if !model
          return nil
        end
        translation_class_name = "#{model.name}::Translation"

        if !Object.const_defined?(translation_class_name)
          return nil
        end

        if return_class_or_name == :class
          return translation_class_name.constantize rescue nil
        end

        return translation_class_name

      end

      def include_models(*models)
        c = self # config
        models.each do |model|
          next if c.respond_to?(:table_exists?) && !c.table_exists?
          c.included_models += [model]

          if !model.instance_of?(Class)
            Dir[Rails.root.join("app/models/#{model.underscore}")].each do |file_name|
              require file_name
            end

            model = model.constantize rescue nil
          end

          #if model.respond_to?(:translates?) && model.translates?
          #if model.respond_to?(:translates?) && model.translates? && model.respond_to?(:translation_class)
          translation_class = resolve_translation_class(model, :class)
          if translation_class && (!translation_class.respond_to?(:table_exists?) || translation_class.table_exists?)
            c.included_models += [translation_class]
          end
        end
      end

      def configure_forms(*form_classes, **options)
        return if form_classes.blank?
        nav_label_key = options[:navigation_label_key] || :settings
        Dir[Rails.root.join("app/models/form_configs/*")].each{|s| require s }
        forms = form_classes
        if form_classes[0] == :all
          forms = Dir[Rails.root.join("app/models/form_configs/*.rb")].map{|s| s.split("/").last.split(".").first.camelize }
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
            navigation_label_key(nav_label_key)
            field :email_receivers, :text do
              help "please write each email in new line"
            end
          end
        end

        config.include_models *forms

        forms.each do |m|
          if m.is_a?(String)
            m = (Object.const_get(m) rescue nil) || m
          end

          begin
            config.model m do
              navigation_label_key(:feedbacks)

              fields_method = m.respond_to?(:rails_admin_fields) ? :fields : (m.respond_to?(:fields_from_model) ? :fields_from_model : nil)
              if fields_method
                edit do
                  field_names = m.send(fields_method)
                  field_names.each do |k|
                    field k do
                      read_only true
                    end
                  end
                end
              end
            end
          rescue

          end
        end
      end

      def model_translation(model, &block)
        if defined?(Attachable::Asset) && model == Attachable::Asset && (!model.respond_to?(:translation_class) || !model.translation_class.table_exists? )
          return
        end
        translation_class = resolve_translation_class(model, :class)
        #if model.respond_to?(:translation_class)
        return if translation_class.respond_to?(:table_exists?) && !translation_class.table_exists?
        if translation_class
          #self.model(model.translation_class, &block)
          self.model translation_class do
            visible false
            field :locale, :hidden
            self.instance_eval(&block)
          end
        end
      end

      def model(entity, &block)


        key = begin
          if entity.is_a?(RailsAdmin::AbstractModel)
            entity.model.try(:name).try :to_sym
          elsif entity.is_a?(Class)
            entity.name.to_sym
          elsif entity.is_a?(String) || entity.is_a?(Symbol)
            entity.to_sym
          else
            entity.class.name.to_sym
          end
        end

        if block
          if entity.respond_to?(:table_exists?) && !entity.table_exists?
            return
          end
          self.include_models(entity)
          if @registry[key].respond_to?(:add_deferred_block)
            @registry[key].add_deferred_block(&block)
          else
            @registry[key] = RailsAdmin::Config::LazyModel.new(entity, &block)
          end
        else
          @registry[key] ||= RailsAdmin::Config::LazyModel.new(entity)
        end
        @registry[key]
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