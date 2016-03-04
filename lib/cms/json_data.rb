module JsonData
  module ActiveRecordExtensions
    module ClassMethods
      def field name, force = false
        if force || !self.class_variable_defined?(:@@_fields)
          self.class_variable_set :@@_fields, []
          after_initialize :assign_attributes_from_json_field
          before_save :serialize_attributes_to_json_field
        end
        fields = self.class_variable_get(:@@_fields)
        if !fields.include?(name)
          fields << name
          self.class_variable_set :@@_fields, fields
          attr_accessor name
          attr_accessible name
        end
      end

      def fields *names, **opts
        names.each_with_index do |name, index|
          field name, index > 0
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
        field_names = self.class.class_variable_get(:@@_fields)
        data = {}
        field_names.each do |field_name|
          data[field_name.to_sym] = self.instance_variable_get("@#{field_name}")
        end
        send("#{json_field}=", data.to_json)

      end
    end
  end
end

ActiveRecord::Base.send(:extend, JsonData::ActiveRecordExtensions::ClassMethods)
ActiveRecord::Base.send(:include, JsonData::ActiveRecordExtensions::InstanceMethods)