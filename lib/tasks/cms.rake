require Rails.root.join('config/environment').to_s


namespace :cms do
  desc "Clear cached html from public"
  task :clear_cache do
    puts Cms::Caching.cacheable_models.map(&:name).inspect
    Cms::Caching.clear_cache
  end

  desc "precompile assets: can specify assets relative public/assets folder"
  task :precompile do
    GLOBAL_ARGV = ARGV
    Rake::Task['environment'].invoke
    Rake::Task['assets:precompile'].invoke
    puts "SET FILE MODE 777 to tmp/cache/assets"
    chmod_folders = [Rails.root.join("tmp/cache/assets")]
    chmod_folders.each do |folder|
      `chmod 777 #{folder} -R`
    end

    #puts "ARGV"
    #puts ARGV.inspect

    #Sprockets::Manifest

  end
end