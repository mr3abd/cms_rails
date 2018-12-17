module Cms
  module DbChanges
    def self.latest_changes(limit = 1, min_date_time = nil, max_date_time = nil, select_column_names = nil, date_column_name = nil)
      select_column_names ||= [:updated_at]
      date_column_name ||= :updated_at
      date_column_name = date_column_name.to_s

      tables_to_scan = Cms.tables.select { |t| Cms.column_names(t, [column_name]).count > 0 }
      changed_tables = tables_to_scan.map do |t|
        table_changes(t, date_column_name, select_column_names, limit, min_date_time, max_date_time)
      end.select { |t| t[:rows].any? }.sort_by { |t| t[:rows].first[column_name] }


      table_top_separator = 10.times.map { "=" }.join("")
      table_header_separator = 10.times.map { "-" }.join("")
      table_bottom_separator = 10.times.map { "=" }.join("") + "\n\n\n"

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

    def self.table_changes(table_name, date_column_name = :updated_at, select_column_names = nil, limit = 0, min_date_time = nil, max_date_time = nil)
      date_column_name = date_column_name.to_s

      if select_column_names == :all
        sql_column_names_str = '*'
      else
        sql_column_names_str = select_column_names.map(&:to_s).join(',')
      end

      q = "select #{sql_column_names_str} from #{table_name} ORDER BY #{date_column_name} desc"
      if limit.is_a?(String)
        limit = limit.to_i
      end

      if limit.is_a?(Numeric) && limit > 0
        q = q + " LIMIT " + limit.to_s
      end

      rows = ActiveRecord::Base.connection.execute(q)
      rows = rows.map { |r| Hash[column_name, DateTime.parse(r[column_name])] }

      if min_date_time
        if min_date_time.is_a?(String)
          min_date_time = DateTime.parse(min_date_time)
        end
        rows = rows.select { |r| r[column_name] >= min_date_time  }
      end

      if max_date_time
        if max_date_time.is_a?(String)
          max_date_time = DateTime.parse(max_date_time)
        end
        rows = rows.select{|r| r[column_name] <= max_date_time  }
      end

      {table: table_name, rows: rows}
    end
  end
end