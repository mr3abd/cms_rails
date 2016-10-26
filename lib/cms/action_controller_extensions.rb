module ActionControllerExtensions
  module ClassMethods
    def reload_text_translations
      if Rails.env.development?
        before_action do
          Cms::Text.load_translations(true)
        end
      end
    end

    def reload_rails_admin_config
      if Rails.env.development?
        before_action do
          if admin_panel?

            RailsAdminDynamicConfig.configure_rails_admin(false)
          end
        end
      end
    end

    def skip_all_before_action_callbacks
      skip_before_action *_process_action_callbacks.map(&:filter)
    end


  end
end

ActionController::Base.send(:extend, ActionControllerExtensions::ClassMethods)