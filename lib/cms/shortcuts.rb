module Cms
  module Shortcuts
    def tables(mask = nil, with_columns = nil)
      arr = ActiveRecord::Base.connection.tables.sort
      arr = filter_tables(arr, mask)

      if with_columns.present? && with_columns.is_a?(Array)
        with_columns = Hash[with_columns.select(&:present?).map{|e| [e.to_s, nil] }]
      end

      #puts "with_columns_arg: #{with_columns.keys.map(&:to_s).inspect}"

      if with_columns.present?
        arr = arr.select{|t| column_names(t, with_columns.keys.map(&:to_s)).count > 0  }
      end

      arr
    end

    def columns(table_name)
      ActiveRecord::Base.connection.columns(table_name)
    end

    def column_names(table_name, mask = nil, type = nil)
      arr = ActiveRecord::Base.connection.columns(table_name)

      filter_columns(arr, mask, type).map(&:name).sort
    end

    def drop_table(*args)
      ActiveRecord::Base.connection.drop_table(*args)
    end

    def create_table(*args)
      ActiveRecord::Base.connection.create_table(*args)
    end

    def remove_column(*args)
      ActiveRecord::Base.connection.remove_column(*args)
    end

    def add_column(*args)
      ActiveRecord::Base.connection.add_column(*args)
    end

    def filter_columns(array, mask = nil, type = nil)

      array = filter_array(array.map(&:name), mask)

      if type
        if type.is_a?(String) || type.is_a?(Symbol)
          array = array.select{|c| c.type.to_sym == type.to_sym }
        elsif type.is_a?(Array)
          type = type.select(&:present?).map(&:to_s)
          if type.count > 0
            array = array.select{|c| c.type.to_s.in?(type) }
          end
        end
      end

      array
    end

    def filter_tables(array, mask = nil)
      filter_array(array, mask)
    end

    def filter_array(array, mask = nil)
      if mask
        if mask.is_a?(Regexp)
          array = array.select{|item| item.name.to_s.scan(mask).any? }
        elsif mask.is_a?(String) || mask.is_a?(Symbol)
          array = array.select{|item| item.name.to_s.include?(mask.to_s) }
        elsif mask.is_a?(Array)
          array = array.select{|item| mask.map(&:to_s).include?(item.name.to_s) }
        end
      end

      array
    end
  end
end

send(:extend, Cms::Shortcuts)
Cms.send(:extend, Cms::Shortcuts)