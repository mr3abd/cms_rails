module Cms
  module PageUrlHelpers
    def route_name(action = :show)
      member_actions = [:show, :edit, :update, :delete, :destroy]
      model_actions = [:index, :new, :create]

      basic_route_name = self.class.name.demodulize.underscore
      if action == :index
        basic_route_name = basic_route_name.pluralize
      end

      return basic_route_name
    end



    def url(locale = I18n.locale, action = :show)
      named_routes = Rails.application.routes.named_routes
      route = named_routes[route_name] || named_routes["#{route_name}_#{locale}"]
      if route
        req_parts = route.required_parts

        built_parts = {}

        req_parts.each do |part|
          if part == :id
            built_parts[part] = self.to_param
          elsif part == :locale
            built_parts[part] = locale
          else
            if self.respond_to?(part)
              built_parts[part] = self.send(part)
            end
          end
        end

        # Rails.application.routes.url_helpers

        return url_helpers.send("#{route.name}_path", built_parts)
      else
        return nil
      end
    end

    def absolute_url(locale = I18n.locale)
      Cms::Helpers::UrlHelper.helper.absolute_url(self.url(locale))
    end

    def affected_pages
      self.class
    end


  end
end