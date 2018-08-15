module Cms
  module Helpers
    module Breadcrumbs
      def self.included(base)
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

      def _add_breadcrumb(name, options)

        b = { }

        # initialize params
        url = options[:url]
        children = options[:children]
        store = options[:store]
        i18n_scope = options[:i18n_scope]
        separator = options[:separator]
        links = options[:links]
        allow_humanize_name = options[:allow_humanize_name]
        custom_attributes = options[:custom_attributes]

        if name.is_a?(ActiveRecord::Base)
          obj = name
          b[:name] = obj.name
          b[:url] = obj.try(:url)
        end
        name = name.to_s

        i18n_scope = "components.breadcrumbs" if i18n_scope == true || i18n_scope.nil?
        b[:links] = links
        b[:name] = (I18n.t("#{i18n_scope}.#{name}", raise: true) rescue (allow_humanize_name ? name.humanize : name)) if b[:name].blank?
        b[:url] = (url.nil? ? try(:"#{name}_path") : url) if b[:url].blank?
        b[:separator] = separator

        if children.try(:any?)
          children_breadcrumbs = []
          children.each do |child|
            children_breadcrumbs << add_breadcrumb(child, nil, nil, false)
          end

          b[:children] = children_breadcrumbs
        end

        b.merge!(custom_attributes.symbolize_keys)

        if store
          if !@_breadcrumbs
            @_breadcrumbs = []
          end
          @_breadcrumbs << b
        else
          return b
        end
      end

      # name, url = nil, children = nil, store = true, i18n_scope = nil, separator = false, links = [], allow_humanize_name = true
      def add_breadcrumb(name, *args)
        args_order_and_defaults = {
          url: nil,
          children: nil,
          store: true,
          i18n_scope: nil,
          separator: false,
          links: [],
          allow_humanize_name: true,
          custom_attributes: {}
        }
        options = args.extract_options!

        options_from_args = Hash[args.map.with_index do |arg, arg_index|
          key = args_order_and_defaults.keys[arg_index]
          [key, arg]
        end]

        options_for_call = args_order_and_defaults.merge(options_from_args).merge(options)
        _add_breadcrumb(name, options_for_call)
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