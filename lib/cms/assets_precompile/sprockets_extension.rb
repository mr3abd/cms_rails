module Cms
  module AssetsPrecompile
    def self.initialize_precompile
      Cms::AssetsPrecompile::SprocketsExtension.init
    end



    class SprocketsExtension

      def self.init_options(*args)
        puts "init_options: ARGV: #{ARGV.inspect}"
        arr = args
        if arr.empty?
          arr = (ARGV[1] || "").gsub(/\AFILES\=/, "").split(",")
        end

        arr = arr.select(&:present?)

        self.class_variable_set(:@@_precompile_files, arr)
        puts "init_options: @@_precompile_files: #{arr.inspect}"
      end

      def self.precompile_file?(s)

        arr = self.class_variable_get(:@@_precompile_files) rescue true
        return true if arr == true || arr.blank?
        #puts "precompile_file?: #{s}"
        #puts "files: #{arr}"

        return s.in?(arr)
      end

      def self.normalize_args(*args)
        puts "normalize_args: args: #{args.inspect}"

        allowed_files = self.class_variable_get(:@@_precompile_files) rescue []
        puts "normalize_args: allowed_files: #{allowed_files.inspect}"



        return args if allowed_files.include?("all")
        allowed_files = ["app"] if allowed_files.blank?

        allowed_files = allowed_files.map{|path|
          if path == "app"
            assets_root = Rails.root.join("app/assets/").to_s


            #sources = Dir[assets_root + "**/*.{png,jpg,jpeg,gif,svg,coffee,sass,scss,css,erb}"]
            sources = Dir[assets_root + "**/*"].select{|path| !File.directory?(path) }
            puts "sources: #{sources.inspect}"
            sources_logical_paths = sources.map{|path| s = path[assets_root.length, path.length]; slash_index = s.index("/"); slash_index && slash_index >= 0 ? s[slash_index + 1, s.length] : nil }.select{|s| s.present? }
            puts "sources_logical_paths: #{sources_logical_paths.inspect}"
            precompile_paths = Rails.application.config.assets.precompile.select{|s| next false if !s.is_a?(String); true} + ["application.css", "application.js"]
            puts "precompile_paths: #{precompile_paths.inspect}"
            precompile_path_groups = precompile_paths.group_by{|path| parts = path.split("/"); parts.count > 1 ? parts.first : "__root__" }
            slp_normalized_exts = sources_logical_paths.map{|path|
              next path if !path.end_with?(".coffee") && !path.end_with?(".sass") && !path.end_with?(".scss")
              file_name = path.split("/").last
              first_dot = file_name.index(".")
              if !first_dot || first_dot < 0
                next nil
              end

              full_ext = file_name[first_dot + 1, file_name.length]
              ext = nil
              normalized_ext = nil
              source_ext = nil

              if full_ext.end_with?("js.coffee")
                source_ext = "js.coffee"
                normalized_ext = "js"
              elsif full_ext.end_with?("coffee")
                source_ext = "coffee"
                normalized_ext = "js"
              elsif full_ext.end_with?("css.scss")
                source_ext = "css.scss"
                normalized_ext = "css"
              elsif full_ext.end_with?("css.sass")
                source_ext = "css.sass"
                normalized_ext = "css"
              elsif full_ext.end_with?("scss")
                source_ext = "scss"
                normalized_ext = "css"
              elsif full_ext.end_with?("sass")
                source_ext = "sass"
                normalized_ext = "css"
              end

              if source_ext && normalized_ext
                path[0, path.length - source_ext.length] + normalized_ext
              end
            }.select(&:present?).uniq
            sources_logical_paths_to_precompile = slp_normalized_exts.select{|s| ext = s.split(".").last; ext.in?(["jpg", "jpeg", "png", "gif", "svg", "woff", "ttf", "eot"]) || s.in?(precompile_paths) }
            puts "sources_logical_paths_to_precompile: #{sources_logical_paths_to_precompile.inspect}"
            next sources_logical_paths_to_precompile
          end

          path
        }

        return [allowed_files.flatten.uniq]

        sources = args.first.select{|item|
          if item.is_a?(Proc) || item.is_a?(Regexp)
            next item
          end

          if item.is_a?(String)
            next item if item.in?(allowed_files)
          end
        }

        [sources]
      end

      def self.init
        Sprockets::Manifest.class_eval do
          def compile(*args)
            dont_invoke_precompile = ENV["invoke_precompile"] == false || ENV["invoke_precompile"] == 'false'
            Cms::AssetsPrecompile::SprocketsExtension.init_options
            #puts args.inspect
            normalized_args = Cms::AssetsPrecompile::SprocketsExtension.normalize_args(*args)
            logger = Cms::AssetsPrecompile::AssetLogger.new(STDOUT)

            unless environment
              raise Error, "manifest requires environment for compilation"
            end

            filenames              = []
            concurrent_compressors = []
            concurrent_writers     = []

            logger.info("Compile args: #{normalized_args.first.count}")
            logger.info "Start finding assets"
            #return

            current_file_number = 0
            logger.set("total_files", normalized_args.flatten.count)
            if ENV["debug_precompile"]
              puts "normalized_args: #{normalized_args.inspect}"
            end

            find(*normalized_args) do |asset|
              if ENV["debug_precompile"]
                puts "asset logical_path: " + asset.logical_path
              end

              next if !Cms::AssetsPrecompile::SprocketsExtension.precompile_file?(asset.logical_path)
              current_file_number += 1
              files[asset.digest_path] = {
                  'logical_path' => asset.logical_path,
                  'mtime'        => asset.mtime.iso8601,
                  'size'         => asset.bytesize,
                  'digest'       => asset.hexdigest,

                  # Deprecated: Remove beta integrity attribute in next release.
                  # Callers should DigestUtils.hexdigest_integrity_uri to compute the
                  # digest themselves.
                  'integrity'    => Sprockets::DigestUtils.hexdigest_integrity_uri(asset.hexdigest)
              }
              assets[asset.logical_path] = asset.digest_path

              if alias_logical_path = self.class.compute_alias_logical_path(asset.logical_path)
                assets[alias_logical_path] = asset.digest_path
              end

              target = File.join(dir, asset.digest_path)

              if File.exist?(target)
                logger.skipping(target, current_file_number)
              else
                logger.writing(target, current_file_number)
                write_file = Concurrent::Future.execute { asset.write_to target }
                concurrent_writers << write_file
              end
              filenames << asset.filename

              next if environment.skip_gzip?
              gzip = Sprockets::Utils::Gzip.new(asset)
              next if gzip.cannot_compress?(environment.mime_types)
              next if dont_invoke_precompile

              if File.exist?("#{target}.gz")
                logger.skipping("#{target}.gz", current_file_number)
              else
                logger.writing("#{target}.gz", current_file_number)
                concurrent_compressors << Concurrent::Future.execute do
                  write_file.wait! if write_file
                  gzip.compress(target)
                end
              end

            end
            logger.info("Finishing")
            concurrent_writers.each(&:wait!)
            concurrent_compressors.each(&:wait!)
            save

            filenames
          end

        end
      end
    end
  end
end