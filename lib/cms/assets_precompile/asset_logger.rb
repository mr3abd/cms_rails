module Cms
  module AssetsPrecompile
    class AssetLogger < Logger
      def add(severity, message = nil, progname = nil, &block)
        msg = message
        msg = progname
        time_str = Time.now.strftime("%H:%M:%S.%L")
        formatted_message = "[#{time_str}] #{msg} \n"
        #puts "severity: #{severity}, message: #{message.inspect}, progname: #{progname.inspect}"
        @logdev.write(formatted_message)
      end

      def defaults(k = nil)
        h = {
            path_relative_to_public: true
        }
        if k
          h[k.to_sym]
        else
          h
        end
      end

      def set(prop, value)
        self.instance_variable_set(:"@#{prop}", value)
      end

      def get(prop)
        (self.instance_variable_get(:"@#{prop}") rescue defaults(prop)) || defaults(prop)
      end

      def reset(prop)
        self.remove_instance_variable(:"@#{prop}") rescue nil
        defaults(prop)
      end

      def extract_path(file, options = {})

        if get(:path_relative_to_public)
          root = Rails.root.join("public/assets/").to_s
          file.gsub(/\A#{root}/, "")
        else
          file
        end
      end

      def writing(file, file_number, total_files = get("total_files"), options = {})
        formatted_file_path = extract_path(file, options)
        info("[#{file_number}/#{total_files}] Writing #{formatted_file_path}")
      end

      def skipping(file, file_number, total_files = get("total_files"), options = {})
        formatted_file_path = extract_path(file, options)
        info("[#{file_number}/#{total_files}] File already exist: #{formatted_file_path}")
      end
    end
  end
end