module JsonData
  module ActiveRecordExtensions
    module ClassMethods
      def field name, type = :string, options = {}, force = false
        if force || !self.class_variable_defined?(:@@_fields)
          self.class_variable_set :@@_fields, {}
          after_initialize :assign_attributes_from_json_field
          before_save :serialize_attributes_to_json_field
        end
        fields = self.class_variable_get(:@@_fields)
        if !fields.keys.map(&:to_s).include?(name)
          options = {} if options == true || options == false
          if type.is_a?(Hash)
            options = type
            type = :string
          end

          field_hash = { type: type }.merge(options)
          fields[name.to_sym] = field_hash
          self.class_variable_set :@@_fields, fields
          attr_accessor name
          attr_accessible name
        end
      end

      def fields *names, **options

        names.each_with_index do |name, index|
          field name, :string, options, index > 0
        end
      end
    end

    module InstanceMethods
      def assign_attributes_from_json_field json_field = :json_data
        data = if self.respond_to?(json_field)
                 self.send(json_field).try{|data| JSON.parse(data) }
               else
                 nil
               end

        if data.blank?
          return
        end


        data.each do |k, v|
          self.instance_variable_set("@#{k}", v)
        end
      end

      def serialize_attributes_to_json_field json_field = :json_data
        fields = self.class.class_variable_get(:@@_fields)
        data = {}
        fields.each do |field_name, field_definition|
          v = self.instance_variable_get("@#{field_name}")
          converted_value = v
          if field_definition[:type].to_s == 'integer'
            converted_value = v.to_i
          elsif field_definition[:type].to_s.in?( ['bool', 'boolean'])
            if v.blank? || v == "0"
              converted_value = false
            else
              converted_value = true
            end

          end

          data[field_name.to_sym] = converted_value
        end
        send("#{json_field}=", data.to_json)

      end
    end
  end
end

ActiveRecord::Base.send(:extend, JsonData::ActiveRecordExtensions::ClassMethods)
ActiveRecord::Base.send(:include, JsonData::ActiveRecordExtensions::InstanceMethods)