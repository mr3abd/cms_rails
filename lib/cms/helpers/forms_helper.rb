module Cms
  module Helpers
    module FormsHelper
      def self.included(base)
        methods = self.instance_methods
        methods.delete(:included)
        if base.respond_to?(:helper_method)
          base.helper_method methods
        end
      end

      def input resource, attr, options = {}
        attr = attr.to_s

        resource_class = resource.class

        type = options.delete(:type) || "string"

        required = options.delete(:required) || false

        input_tag__id = input_tag_id(resource, attr)
        input_tag_name = input_tag_name(resource, attr)

        input_tag_type = ""
        type = type.to_s
        if type == 'string'
          input_tag_type = "text"
        end

        placeholder_str = placeholder(resource, attr)

        input_tag_str = "<input id='#{input_tag__id}' name='#{input_tag_name}' type='#{input_tag_type}' />"

        if type == 'text'
          input_tag_str = "<textarea id='#{input_tag__id}' name='#{input_tag_name}' ></textarea>"
        end


        input_template(type, required, placeholder_str, input_tag_str).html_safe
      end

      def input_template(type, required, placeholder_str, input_tag_str)
        "<div class='input #{type} #{'required' if required} '>#{placeholder_str}#{input_tag_str}</div>"
      end

      def placeholder(resource, attr, options = {})
        attr = attr.to_s
        resource_name = resource.class.name.underscore.gsub("/", "__")

        input_tag__id = input_tag_id(resource, attr)
        input_tag_name = input_tag_name(resource, attr)

        label_text = Cms.t("forms.#{resource_name}.#{attr}", raise: true) rescue attr.humanize

        "<label class='placeholder' for='#{input_tag__id}'>#{label_text}</label>".html_safe
      end

      def input_tag_id(resource, attr, options = {})
        resource_name = resource.class.name.underscore.gsub("/", "__")

        "#{resource_name}__#{attr}"
      end

      def input_tag_name(resource, attr, options = {})
        resource_name = resource.class.name.underscore.gsub("/", "__")

        "#{resource_name}[#{attr}]"
      end


    end
  end
end
