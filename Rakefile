require "rake"
require "rspec/core/rake_task"
require "bundler/gem_tasks"
task :default => :spec
RSpec::Core::RakeTask.new(:spec)

import "./lib/tasks/cms.rake"
require 'db/backuper'

namespace :db do

  desc "descr"
  task :my_dump => :environment do

  end

end