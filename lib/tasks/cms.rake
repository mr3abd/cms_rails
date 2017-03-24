require Rails.root.join('config/environment').to_s

namespace :cms do
  desc "Clear cached html from public"
  task :clear_cache do
    puts Cms::Caching.cacheable_models.map(&:name).inspect
    Cms::Caching.clear_cache
  end
end