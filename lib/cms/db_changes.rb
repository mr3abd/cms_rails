module Cms
  module DbChanges
    def self.latest_changes(limit = 1, min_date_time = nil)

      column_name = "updated_at"
      tables_to_scan = Cms.tables.select{|t| Cms.column_names(t, column_name).first == column_name }
      changed_tables = tables_to_scan.map{|t|
        q = "select #{column_name} from #{t} ORDER BY #{column_name} desc"
        if limit.is_a?(String)
          limit = limit.to_i
        end

        if limit.is_a?(Numeric) && limit > 0
          q = q + " LIMIT " + limit.to_s
        end

        rows = ActiveRecord::Base.connection.execute(q)
        rows = rows.map{|r| Hash[column_name, DateTime.parse(r[column_name])] }
        if min_date_time
          if min_date_time.is_a?(String)
            min_date_time = DateTime.parse(min_date_time)
          end
          rows = rows.select{|r| r[column_name] >= min_date_time  }
        end

        {table: t, rows: rows}
      }.select{|t| t[:rows].any? }.sort_by{|t| t[:rows].first[column_name] }


      table_top_separator = 10.times.map{"="}.join("")
      table_header_separator = 10.times.map{"-"}.join("")
      table_bottom_separator = 10.times.map{"="}.join("") + "\n\n\n"

      no_changes = changed_tables.blank?
      if no_changes
        puts table_top_separator
        puts "NO CHANGES"
        puts table_top_separator
        return nil
      end


      changed_tables.each do |t|
        puts table_top_separator
        puts t[:table]
        puts table_header_separator
        t[:rows].each do |r|
          puts r.inspect
        end
        puts table_bottom_separator
      end

      nil
    end
  end
end