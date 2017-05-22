module ActiveModel
  class Errors
    def generate_message(attribute, type = :invalid, options = {})
      base = self.instance_variable_get(:@base)

      if base.instance_variable_get(:@_return_json_errors) || base.class.class_variable_defined?(:@@_return_json_errors) && base.class.class_variable_get(:@@_return_json_errors)
        h = {:"type" => type}
        h[:options] = options if options.present?
        h
      else
        original_generate_message(attribute, type, options)
      end
    end

    def original_generate_message(attribute, type = :invalid, options = {})
      type = options.delete(:message) if options[:message].is_a?(Symbol)

      if @base.class.respond_to?(:i18n_scope)
        defaults = @base.class.lookup_ancestors.map do |klass|
          [ :"#{@base.class.i18n_scope}.errors.models.#{klass.model_name.i18n_key}.attributes.#{attribute}.#{type}",
            :"#{@base.class.i18n_scope}.errors.models.#{klass.model_name.i18n_key}.#{type}" ]
        end
      else
        defaults = []
      end

      defaults << options.delete(:message)
      defaults << :"#{@base.class.i18n_scope}.errors.messages.#{type}" if @base.class.respond_to?(:i18n_scope)
      defaults << :"errors.attributes.#{attribute}.#{type}"
      defaults << :"errors.messages.#{type}"

      defaults.compact!
      defaults.flatten!

      key = defaults.shift
      value = (attribute != :base ? @base.send(:read_attribute_for_validation, attribute) : nil)

      options = {
          default: defaults,
          model: @base.model_name.human,
          attribute: @base.class.human_attribute_name(attribute),
          value: value
      }.merge!(options)

      I18n.translate(key, options)
    end
  end
end

class ActiveRecord::Base
  def get_errors(return_json = true)
    self.instance_variable_set(:@_return_json_errors, return_json)
    self.valid?
    self.errors
  end
end