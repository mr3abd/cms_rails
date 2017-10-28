module Cms
  module Helpers
    module NavigationHelper
      def self.included(base)
        methods = self.instance_methods
        methods.delete(:included)
        if base.respond_to?(:helper_method)
          base.helper_method methods
        end
      end

      def menu(menu_keys = nil, i18n_root_or_options = nil, options = {})
        i18n_root = i18n_root_or_options
        if i18n_root.blank? || i18n_root.is_a?(Hash)
          options = i18n_root_or_options
          i18n_root = "menu"
        end

        menu_keys ||= %w(about_us services process benefits teams industries blog contacts)

        compute_navigation_keys(menu_keys, i18n_root, true, options)

      end

      def sitemap_entries(keys = nil, i18n_root = "sitemap")
        keys ||= [{key: "home", url: root_path}, "about_us", "services", "process", {key: "teams", children_class: Team}, {key: "industries", children_class: Industry}, "blog", "contacts", "career", "privacy_policy", "terms_of_use" ]

        compute_navigation_keys(keys, i18n_root, false)
      end

      def read_also_entries
        compute_navigation_keys(@read_also_entries, "read_also")
      end

      def compute_navigation_keys(keys, i18n_root = "navigation", check_for_active = true, options = {})
        puts "compute_navigation_keys: #{keys.inspect}; i18n_root: #{i18n_root.inspect}; check_for_active: #{check_for_active.inspect}; options: #{options.inspect}"
        defaults = {
            i18n_title_key: false,
            i18n_html_title_key: false
        }
        settings = defaults.merge(options || {})
        h = {}
        keys.keep_if{|e|  ( (e.is_a?(String) || e.is_a?(Symbol)) && e.present? ) ||  (e.is_a?(Hash) || e[:key].present?)   }.each do |key|
          entry = {}
          if key.is_a?(String) || key.is_a?(Symbol)
            entry[:key] = key.to_sym
          elsif key.is_a?(Hash)
            entry = key
          end


          if settings[:i18n_title_key] == true
            settings[:i18n_title_key] = "title"
          end

          if settings[:i18n_html_title_key] == true
            settings[:i18n_html_title_key] = "html-title"
          end

          if entry[:key].blank? && entry[:controller].present?
            entry[:key] = entry[:controller].to_s
          end

          if settings[:i18n_title_key]
            entry[:name] ||= (Cms.t("#{i18n_root}.#{settings[:i18n_title_key]}.#{entry[:key]}", raise: true) rescue nil)
          end

          if settings[:i18n_html_title_key]
            entry[:title] ||= (Cms.t("#{i18n_root}.#{settings[:i18n_html_title_key]}.#{entry[:key]}", raise: true) rescue nil)
          end

          entry[:name] ||= (Cms.t("#{i18n_root}.#{entry[:key]}", raise: true) rescue entry[:key].to_s.humanize)

          entry[:url] ||= send("#{entry[:key]}_path")

          if (children_class = entry[:children_class])
            scopes = %w(published sort_by_position sort_by_sorting_position).select{|s| children_class.respond_to?(s) }

            children = children_class.all
            if scopes.any?
              scopes.each do |s|
                children = children.send(s)
              end
            end

            entry[:children] = children
          end


          #active = params[:route_name].to_s == key

          h[entry[:key]] = entry




          if check_for_active && entry[:active].nil?
            if entry[:controller]
              active = controller_name == entry[:controller] && action_name == "index"
            else
              active = controller_name == key || (action_name == key && controller_name == "pages") || params[:route_name].to_s == key || @page_instance.try(:url) == entry[:url]
            end

            if !active
              if entry[:controller]
                has_active = controller_name == entry[:controller]
              else

              end
            end

            entry[:active] = active
            entry[:has_active] = has_active || false
          end

        end

        h
      end

      def recursive_menu(menu_items, i18n_scope = "menu")
        arr = [menu_items].flatten
        if arr.blank?
          return []
        end

        if arr.count == 1
          h = arr[0]

          key = h
          if key.is_a?(String) || key.is_a?(Symbol)
            h = {key: key}
            h[:resource] = Pages.send(key) if !h[:resource]
            h[:name] ||= Cms.t("#{i18n_scope}.#{key}", raise: true) rescue nil
            h[:name] = key.to_s.humanize if h[:name].blank?
          elsif key.is_a?(ActiveRecord::Base)
            resource = key
            key = key.class.name.split("::").last.underscore
            h = {key: key}
            h[:resource] = resource if !h[:resource]
            h[:name] ||= h[:resource].try(:name)
            h[:url] = resource.url

          else
            key = h[:key]
            if h[:resource].nil?
              h[:resource] = Pages.send(key) if !h[:resource]
            end
            h[:name] ||= Cms.t("#{i18n_scope}.#{key}", raise: true) rescue I18n.t("#{i18n_scope}.#{key}", raise: true) rescue nil
            h[:name] = key.to_s.humanize if h[:name].blank?
          end



          h[:url] ||= h[:resource].url || h[:resource].try(:default_url)



          if h[:children].present?
            h[:children] = [recursive_menu(h[:children])].flatten
          end


          h[:action] = nil if h[:action].blank?



          if h[:active].nil?
            if h[:controller]
              action = h[:action]
              action = "index" if action.blank?

              h[:active] = controller_name == h[:controller].to_s && action_name == action.to_s
            else
              h[:active] = h[:resource] == @page_instance
            end
          end



          if !h[:active] && h[:has_active].nil?
            if h[:controller]
              if h[:action]
                h[:has_active] = action_name == h[action]
              else
                h[:has_active] = controller_name == h[:controller].to_s && action_name == options_controller_action
              end

            end
            if h[:has_active].nil?
              has_active = h[:children]
                               .try{|children| children.any?{|child| child[:active] rescue false } } || false

              h[:has_active] = has_active
            end
          end

          return h
        else
          return arr.map{|item| recursive_menu(item)}

        end


      end

      def footer_menu
        menu
      end

      def additional_links
        menu(%w(terms_of_use privacy_policy career sitemap), "additional_links")
      end

      def menu_item_tag(item, options = {}, attrs = nil)
        defaults = {
            wrap_tag: :li
        }
        settings = defaults.merge(options)
        show_url = item[:url].present? && !item[:active]
        item_tag = show_url ? :a : :span
        item_attrs = {}
        item_attrs[:href] = item[:url] if show_url
        item_attrs[:title] = item[:title] if item[:title].present?
        item_attrs[:class] = "menu-item"
        item_attrs[:class] += " active" if item[:active]
        item_attrs[:class] += " has-active" if item[:has_active]

        attrs ||= {}
        item_attrs = item_attrs.merge(attrs)


        item_tag = content_tag(item_tag, item[:name], item_attrs)
        if settings[:wrap_tag]
          content_tag(settings[:wrap_tag], item_tag)
        else
          raw item_tag
        end
      end
    end
  end
end