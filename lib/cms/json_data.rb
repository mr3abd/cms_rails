module JsonData
  module ActiveRecordExtensions
    module ClassMethods
      def json_field(name, type = :array)
        empty_value = nil
        if type.to_sym == :array
          empty_value = []
        elsif type.to_sym == :hash
          empty_value = {}
        end
        define_method name do
          JSON.parse(self[name.to_s]) rescue empty_value
        end

        define_method "#{name}=" do |val|
          json_value = val
          if !val.is_a?(String)
            json_value = val.to_json
          end
          self[name.to_s] = json_value

          return true
        end
      end

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

          field_hash = { type: type, group: :default }.merge(options)
          fields[name.to_sym] = field_hash
          self.class_variable_set :@@_fields, fields
          #attr_accessor name
          attr_accessible name

          define_method name do
            instance_variable_get(:"@#{name}") rescue nil
          end

          define_method "#{name}=" do |val|
            instance_variable_set(:"@#{name}", val)
            serialize_attributes_to_json_field

          end

        end
      end

      def fields *names, **options
        puts "names: #{names.inspect}; names.empty?: #{names.empty?.inspect}"
        if names.empty?
          fields_arr = class_variable_get(:@@_fields)
          return fields_arr.select{|field_key, field_definition| diff = 0; options.each{|opt_key, opt_value| diff += 1 if field_definition[opt_key] != opt_value; }; next diff == 0  }
        end

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