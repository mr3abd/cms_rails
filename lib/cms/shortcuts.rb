module Cms
  module Shortcuts
    def tables(mask = nil)
      arr = ActiveRecord::Base.connection.tables.sort
      if mask.is_a?(Regexp)
        arr.select{|item| item.to_s.scan(mask).any? }
      else
        arr
      end
    end
  end
end

send(:extend, Cms::Shortcuts)