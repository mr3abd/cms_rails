require 'rails/generators'
require File.expand_path('../utils', __FILE__)

module Cms
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    include Generators::Utils::InstanceMethods

    def install
      locales_string = ask_for('Locales(space separated array)', 'en uk ru')
      @locales = locales_string.split(" ")
      @use_translations = locales_string.length > 1
      add_gems
      add_routes
      add_initializers



      #template 'initializer.erb', 'config/initializers/rails_admin.rb'
    end

    private
    def add_gems
      gem 'slim-rails', '3.1.1'
      gem "html2slim"
      gem 'bower-rails'
      gem "protected_attributes"

      gem 'rails_admin'
      gem 'rails_admin_nestable'

      gem 'figaro'

      gem 'devise'

      gem 'enumerize'

      gem 'ckeditor'

      gem 'paperclip'
      gem 'paperclip-tinify'

      gem 'pluck_to_hash'

      gem 'yaml_db'

      gem 'quiet_assets'

      gem "htmlcompressor"
      gem 'rack-page_caching'

      gem 'puma'

      gem 'ace-rails-ap'

      gem 'i18n-active_record',
          github: 'svenfuchs/i18n-active_record',
          require: 'i18n/active_record'

      gem 'rails-i18n'
      gem "devise-i18n"


      gem 'pg'

      if @use_translations
        gem 'globalize'
        gem 'rails_admin_globalize_field'
        gem 'route_translator'
      end
    end

    def add_initializers

    end

    def add_gitignore
      append_to_file ".gitignore", "\nconfig/application.yml"
    end

    def add_models

    end

    def add_routes
      route("mount Cms::Engine => '/', as: 'cms'")
      route("mount Ckeditor::Engine => '/ckeditor'")

      if @use_translations
        route('get "admin(/*admin_path)", to: redirect{|params| "/#{ I18n.default_locale}/admin/#{params[:admin_path]}"}')
        route('root as: "root_without_locale", to: "application#root_without_locale"')
      end
    end
  end
end