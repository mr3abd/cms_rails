module Cms
  module Helpers
    module Breadcrumbs
      def self.included(base)
        #methods = self.instance_methods
        #methods.delete(:included)
        methods = [:render_breadcrumbs]
        if base.respond_to?(:helper_method)
          base.helper_method methods
        end

      end

      def initialize_breadcrumbs
        if controller_name.in?(%w[articles catalog pages services]) && (controller_name != 'pages' || action_name != 'index')
          @_breadcrumbs = []
          add_home_breadcrumb
        end
      end

      def add_breadcrumb(name, url = nil, children = nil, store = true, i18n_scope = "components.breadcrumbs", separator = false)
        b = { }

        if name.is_a?(ActiveRecord::Base)
          obj = name
          b[:name] = obj.name
          b[:url] = obj.url
        end
        name = name.to_s

        b[:name] = (I18n.t("#{i18n_scope}.#{name}", raise: true) rescue name.humanize) if b[:name].blank?
        b[:url] = (url.nil? ? send("#{name}_path") : url) if b[:url].blank?
        b[:separator] = separator

        if children.try(:any?)
          children_breadcrumbs = []
          children.each do |child|
            children_breadcrumbs << add_breadcrumb(child, nil, nil, false)
          end

          b[:children] = children_breadcrumbs
        end

        if store
          @_breadcrumbs << b
        else
          return b
        end
      end

      def add_home_breadcrumb
        add_breadcrumb(Pages.home, Pages.home.url)
      end

      def render_breadcrumbs
        raw(render_to_string partial: "breadcrumbs")
      end
    end
  end
end