namespace :cms do
  desc "Clear cached html from public"
  task :clear_cache do
    Cms::Caching.clear_cache
  end
end