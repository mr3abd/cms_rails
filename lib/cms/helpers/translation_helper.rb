module Cms
  module Helpers
    module TranslationHelper
      def self.included(base)
        methods = self.instance_methods
        methods.delete(:included)
        if base.respond_to?(:helper_method)
          base.helper_method methods
        end

      end

      def t(*args)

        if args.first.is_a?(String) && args.first.start_with?(".")
          relative_path = args.first.gsub(/\A\./, "")
          relative_path_keys = relative_path.split(".")
          req_params = params rescue nil
          if req_params
            controller_name = req_params[:controller]
                                  .split("/").map{|s| s.capitalize }.join("::")
            controller_action = req_params[:action]

            controller_class = Object.const_get(controller_name) rescue nil
            classes = controller_class.parent_classes(ActionController::Base)
            full_path_keys = classes.map{|c| (c.name.split("::").map{|s| s.underscore } + [controller_action, *relative_path_keys] ).join(".") }
            args[0] = full_path_keys
          end
        end
        Cms.t(*args)
      end
    end
  end
end
