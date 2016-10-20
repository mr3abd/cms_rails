module Cms
  module Shortcuts
    def tables
      ActiveRecord::Base.connection.tables.sort
    end
  end
end

send(:extend, Cms::Shortcuts)