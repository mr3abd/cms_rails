module Cms
  module AssetsPrecompile

    def self.initialize_precompile
      Cms::AssetsPrecompile::SprocketsExtension.init
    end

    class SprocketsExtension
      def self.init
        Sprockets::Manifest.class_eval do
          def compile(*args)
            logger = Cms::AssetsPrecompile::AssetLogger.new(STDOUT)

            unless environment
              raise Error, "manifest requires environment for compilation"
            end

            filenames              = []
            concurrent_compressors = []
            concurrent_writers     = []

            logger.info("Compile args: #{args.first.count}")
            logger.info "Start finding assets"
            #return

            current_file_number = 0
            logger.set("total_files", args.flatten.count)

            find(*args) do |asset|
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