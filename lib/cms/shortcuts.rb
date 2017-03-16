module Cms
  module Shortcuts
    def tables(mask = nil, with_columns = nil)
      arr = ActiveRecord::Base.connection.tables.sort
      arr = filter(arr, mask)

      if with_columns.present? && with_columns.is_a?(Array)
        with_columns = Hash[arr.select(&:present?).map{|e| [e.to_s, nil] }]
      end

      puts "with_columns_arg: #{with_columns.keys.map(&:to_s).inspect}"

      if with_columns.present?
        arr = arr.select{|t| column_names(t, with_columns.keys.map(&:to_s)).count > 0  }
      end

      arr
    end

    def columns(table_name)
      ActiveRecord::Base.connection.columns(table_name)
    end

    def column_names(table_name, mask = nil)
      arr = ActiveRecord::Base.connection.columns(table_name).map(&:name)
      filter(arr, mask).sort
    end

    def drop_table(*args)
      ActiveRecord::Base.connection.drop_table(*args)
    end

    def create_table(*args)
      ActiveRecord::Base.connection.create_table(*args)
    end

    def filter(array, mask = nil)

      if mask.is_a?(Regexp)
        array = array.select{|item| item.to_s.scan(mask).any? }
      elsif mask.is_a?(String) || mask.is_a?(Symbol)
        array = array.select{|item| item.to_s.include?(mask.to_s) }
      elsif mask.is_a?(Array)
        array = array.select{|item| mask.map(&:to_s).include?(item.to_s) }
      end

      array
    end
  end
end

send(:extend, Cms::Shortcuts)
Cms.send(:extend, Cms::Shortcuts)