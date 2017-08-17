module ActionControllerExtensions
  module ClassMethods
    def reload_text_translations
      if Rails.env.development?
        before_action do
          Cms::Text.load_translations(true)
        end
      end
    end

    def reload_rails_admin_config(models_to_reload = :all)
      if Rails.env.development?
        before_action do
          if admin_panel?
            if models_to_reload == :all
              RailsAdmin::Config.reset
            else
              if models_to_reload.present?
                if !models_to_reload.respond_to?(:each)
                  models_to_reload = [models_to_reload]
                end

                models_to_reload.each do |m|
                  RailsAdmin::Config.reset_model(m)
                  #Object.send(:remove_const, m) if Object.const_defined?(m)
                  #model_base_dir = Rails.root.join("app/models/").to_s
                  #model_path = model_base_dir + m.underscore + ".rb"
                  #load Rails.root.join(model_path)
                end
              end
            end
            RailsAdminDynamicConfig.configure_rails_admin(false)
          end
        end
      end
    end

    def skip_all_before_action_callbacks
      skip_before_action *_process_action_callbacks.map(&:filter)
    end


  end

  module InstanceMethods
    def self.included(base)
      if base.respond_to?(:helper_method)
        methods = [:asset_path]
        base.helper_method *methods
      end
    end

    def asset_path(url)
      ActionController::Base.helpers.asset_path(url)
    end
  end
end

ActionController::Base.send(:extend, ActionControllerExtensions::ClassMethods)
#ActionController::Base.send(:include, ActionControllerExtensions::InstanceMethods)