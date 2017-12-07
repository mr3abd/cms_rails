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

      def day_hours_combination(prefix = nil)
        day_fields_combination({"day_%d_start" => :integer, "day_%d_end" => :integer}, {"days_%d1_to_%d2_start" => :integer, "days_%d1_to_%d2_end" => :integer})
      end



      def day_fields_combination(each_day_columns, day_groups_columns, day_groups = nil, combination_column_name = nil, prefix = nil)
        if prefix.present? && !prefix.end_with?("_")
          prefix += "_"
        end

        columns = {}

        if day_groups.nil?
          day_groups = [[1, 5], [6,7], [1, 7]]
        end

        7.times do |i|
          n = i + 1
          each_day_columns.each do |column_name, column_type|
            column_name = "#{prefix}#{column_name}".gsub("%d", n.to_s)
            columns[column_name.to_sym] ||= column_type
          end
        end

        day_groups.each do |day_group|
          d1 = day_group[0]
          d2 = day_group[1]
          day_groups_columns.each do |column_name, column_type|
            column_name = "#{prefix}#{column_name}".gsub("%d1", d1.to_s).gsub("%d2", d2.to_s)
            columns[column_name.to_sym] ||= column_type
          end
        end

        if combination_column_name.nil?
          combination_column_name = "days_combination"
        end

        combination_column_name = "#{prefix}#{combination_column_name}"

        columns[combination_column_name.to_sym] ||= :string

        columns

      end


    end
  end
end

ActiveRecord::ConnectionAdapters::TableDefinition.send :include, ActiveRecordExtensions::Linkable::TableDefinition
ActiveRecord::ConnectionAdapters::Table.send :include, ActiveRecordExtensions::Linkable::TableDefinition

ActiveRecord::ConnectionAdapters::TableDefinition.send :include, ActiveRecordExtensions::Utils::TableDefinition
ActiveRecord::ConnectionAdapters::Table.send :include, ActiveRecordExtensions::Utils::TableDefinition
