module ActiveRecordExtensions
  module Linkable
    module TableDefinition
      def linkable(*args)
        options = args.extract_options!
        name = args[0]
        name = :linkable if name.blank?
        #options.reverse_merge!({ precision: 8, scale: 2 })
        #column_names = args
        column("#{name}_id", :integer, options)
        column("#{name}_type", :string, options)
      end

      def image(*args)
        attachment(*args)
      end
    end
  end

  module Utils
    module TableDefinition
      def address(options = {})
        prefix = options[:prefix]
        prefix = "" if prefix.blank?
        prefix += "_" if prefix.present? && !prefix.end_with?("_")
        string "#{prefix}address"
        string "#{prefix}state"
        string "#{prefix}city"
        string "#{prefix}zip_code"
      end

      def day_hours_combiation(prefix = nil)
        if prefix.present? && !prefix.end_with?("_")
          prefix += "_"
        end

        7.times do |i|
          n = i + 1
          integer :"#{prefix}day_#{n}_start"
          integer :"#{prefix}day_#{n}_end"
        end

        integer :"#{prefix}days_1_to_5_start"
        integer :"#{prefix}days_1_to_5_end"
        integer :"#{prefix}days_6_to_7_start"
        integer :"#{prefix}days_6_to_7_end"
        integer :"#{prefix}days_1_to_7_start"
        integer :"#{prefix}days_1_to_7_end"

        string :"#{prefix}days_combination"
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::TableDefinition.send :include, ActiveRecordExtensions::Linkable::TableDefinition
ActiveRecord::ConnectionAdapters::Table.send :include, ActiveRecordExtensions::Linkable::TableDefinition

ActiveRecord::ConnectionAdapters::TableDefinition.send :include, ActiveRecordExtensions::Utils::TableDefinition
ActiveRecord::ConnectionAdapters::Table.send :include, ActiveRecordExtensions::Utils::TableDefinition
