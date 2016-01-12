module Cms
  module PageUrlHelpers
    def route_name(action = :show)
      basic_route_name = self.class.name.demodulize.underscore
      if action == :show

      end

      return basic_route_name
    end



    def url(action = :show)
      route = Rails.application.routes.named_routes[route_name]
      req_parts = route.required_parts
      built_parts = {}
      req_parts.each do |part|
        if part == :id
          built_parts[part] = self.to_param
        else
          if self.respond_to?(part)
            built_parts[part] = self.send(part)
          end
        end
      end

      # Rails.application.routes.url_helpers

      url_helpers.send("#{route_name}_path", built_parts)
    end
  end
end