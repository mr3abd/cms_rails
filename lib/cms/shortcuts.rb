module Cms
  module Shortcuts
    def tables(mask = nil)
      arr = ActiveRecord::Base.connection.tables.sort
      filter(arr, mask)
    end

    def columns(table_name)
      ActiveRecord::Base.connection.columns(table_name)
    end

    def column_names(table_name, mask = nil)
      arr = ActiveRecord::Base.connection.columns(table_name).map(&:name)
      filter(arr, mask).sort
    end

    def filter(array, mask = nil)
      if mask.is_a?(Regexp)
        array.select{|item| item.to_s.scan(mask).any? }
      elsif mask.is_a?(String) || mask.is_a?(Symbol)
        array.select{|item| item.to_s.include?(mask.to_s) }
      else
        array
      end
    end
  end
end

send(:extend, Cms::Shortcuts)