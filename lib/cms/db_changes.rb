module Cms
  module DbChanges
    def self.latest_changes(limit = 1, min_date_time = nil, max_date_time = nil, select_column_names = nil, date_column_name = nil, output_target = nil)
      output_target ||= :console
      select_column_names ||= [:updated_at]
      date_column_name ||= :updated_at
      date_column_name = date_column_name.to_s

      tables_to_scan = Cms.tables.select { |t| Cms.column_names(t, [date_column_name]).count > 0 }
      changed_tables = tables_to_scan.map do |t|
        table_changes(t, date_column_name, select_column_names, limit, min_date_time, max_date_time)
      end.select { |t| t[:rows].any? }.sort_by { |t| t[:rows].first[date_column_name] }

      table_top_separator = 10.times.map { "=" }.join("")
      table_header_separator = 10.times.map { "-" }.join("")
      table_bottom_separator = 10.times.map { "=" }.join("") + "\n\n\n"

      output = ""
      options = {
        limit: limit,
        min_date_time: min_date_time,
        max_date_time: max_date_time,
        select_column_names: select_column_names,
        date_column_name: date_column_name
      }

      no_changes = changed_tables.blank?
      if no_changes
        output += "\n" + table_top_separator
        output += "\n" + "NO CHANGES"
        output += "\n" + table_top_separator
        output_target_info = write_db_changes(options, output, output_target)
        if output_target_info.is_a?(Hash) && output_target_info[:message].present?
          puts output_target_info[:message]
        end
        return nil
      end

      changed_tables.each do |t|
        table_top_separator
        output += "\n" + t[:table]
        output += "\n" + table_header_separator
        t[:rows].each do |r|
          output += "\n" + r.inspect
        end
        output += "\n" + table_bottom_separator
      end

      write_db_changes_to_file(options, output)

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
      rows = normalize_rows(rows, date_column_name)

      if min_date_time
        if min_date_time.is_a?(String)
          min_date_time = DateTime.parse(min_date_time)
        end
        rows = rows.select { |r| r[date_column_name] >= min_date_time  }
      end

      if max_date_time
        if max_date_time.is_a?(String)
          max_date_time = DateTime.parse(max_date_time)
        end
        rows = rows.select{|r| r[date_column_name] <= max_date_time  }
      end

      {table: table_name, rows: rows}
    end

    def self.normalize_rows(rows, date_column_name)
      date_column_name = date_column_name.to_s
      date_time_column_names = ['updated_at', 'created_at']
      unless date_time_column_names.index(date_column_name)
        date_time_column_names << date_column_name
      end

      rows.map { |r|
        date_time_column_names.each do |date_time_column_name|
          if r[date_time_column_name]
            r[date_time_column_name] = DateTime.parse(r[date_time_column_name])
          end
        end

        r
      }
    end

    def self.write_db_changes(options, content, output_target)
      if output_target.to_s == 'file'
        file_path = write_db_changes_to_file(options, content)
        return { message: "File saved at #{file_path}" }
      else
        puts content
      end
    end

    def self.write_db_changes_to_file(options, content)
      file_dirname = Rails.root.join('db/').to_s
      file_name = "db_changes"
      if options[:min_date_time]
        file_name += "_from_#{options[:min_date_time].to_s.underscore}"
      end

      if options[:max_date_time]
        file_name += "_to_#{options[:max_date_time].to_s.underscore}"
      end

      file_name += "_at_#{DateTime.now.to_s.underscore}"
      file_name += '.txt'

      file_path = "#{file_dirname}#{file_name}"

      header = "DbChanges.latest_changes options: " + options.inspect

      full_content = "#{header}\n\n#{content}"

      File.write(file_path, full_content)

      return file_path
    end
  end
end