module Cms
  module AssetsPrecompile
    def self.initialize_precompile
      Cms::AssetsPrecompile::SprocketsExtension.init
    end



    class SprocketsExtension

      def self.init_options(*args)
        arr = args
        if arr.empty?
          arr = (ARGV[1] || "").gsub(/\AFILES\=/, "").split(",")
        end

        self.class_variable_set(:@@_precompile_files, arr)
      end

      def self.precompile_file?(s)

        arr = self.class_variable_get(:@@_precompile_files) rescue true
        return true if arr == true || arr.blank?
        #puts "precompile_file?: #{s}"
        #puts "files: #{arr}"

        return s.in?(arr)
      end

      def self.normalize_args(*args)
        #puts "normalize_args: args: #{args.inspect}"

        allowed_files = self.class_variable_get(:@@_precompile_files) rescue []

        return args if allowed_files.blank?

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

            find(*normalized_args) do |asset|
              next if ENV["debug_precompile"]
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