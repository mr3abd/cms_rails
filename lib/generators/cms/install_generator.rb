require 'rails/generators'
require File.expand_path('../utils', __FILE__)

module Cms
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    include Generators::Utils::InstanceMethods

    def install
      locales_string = ask_for('Locales(space-separated list)', 'en uk ru')
      @locales = locales_string.split(" ")
      @use_translations = locales_string.length > 1

      @pages = ask_for("Pages(space-separated list)", "home about_us contacts articles").split(" ")
      @form_keys = ask_for("Forms(space-separated list)", "contact_request").split(" ")
      @forms = {}
      @form_keys.each do |form|
        @forms[form.underscore.to_sym] = ask_for("Form `#{form}` fields: ", "name email phone comment:text")
      end
      @rails_admin_menu_sections = ask_for("RailsAdmin menu sections(space-separated list) ", "feedbacks home about_us blog news contacts terms_of_use tags users settings pages assets").split(" ")
      @database_engine = ask_for("Database engine: 1. postgres; 2. sqlite", "1")
      @database_engine = @database_engine == "1" ? "postgres" : "sqlite"
      if @database_engine == "sqlite"
        @database_name = Rails.env.to_s
      else
        @database_name = ""
      end

      @database_name = ask_for("Database name: ", @database_name)

      add_gems
      add_routes
      add_initializers
      add_models
      init_application_rb
      init_application_yml
      init_application_controller
      add_controllers
      add_forms


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
      file_names = ["ckeditor", "cms", "devise", "rails_admin", "require_lib", "smtp_settings"]
      if @use_translations
        file_names << "route_translator"
      end
      file_names.each do |file_name|
        template "initializers/#{file_name}.rb.erb", "config/initializers/#{file_name}.rb"
      end
    end

    def add_gitignore
      append_to_file ".gitignore", "\nconfig/application.yml"
    end

    def add_models
      @pages.each do |page_name|
        Rails::Generators.invoke("cms:page", [page_name, "--use-translations #{@use_translations}"])
      end

      template "models/rails_admin_dynamic_config.rb.erb", "app/models/rails_admin_dynamic_config.rb"
      template "models/user.rb.erb", "app/models/user.rb"
    end

    def add_routes
      if @use_translations
        route("localized do\n  end\n")

        route('root as: "root_without_locale", to: "application#root_without_locale"')
        route('get "admin(/*admin_path)", to: redirect{|params| "/#{ I18n.default_locale}/admin/#{params[:admin_path]}"}')
      end

      route("mount Ckeditor::Engine => '/ckeditor'")
      route("mount Cms::Engine => '/', as: 'cms'")

      insert_into_file("config/routes.rb", "  match '*url', to: 'application#render_not_found', via: :all\n", before: /^end/)


    end

    def init_application_controller
      lines = []
      lines << "include ActionView::Helpers::OutputSafetyHelper"
      lines << "include Cms::Helpers::ImageHelper"
      lines << "include ActionView::Helpers::AssetUrlHelper"
      lines << "include ActionView::Helpers::TagHelper"
      lines << "include ActionView::Helpers::UrlHelper"
      lines << "include Cms::Helpers::UrlHelper"
      lines << "include Cms::Helpers::PagesHelper"
      lines << "include Cms::Helpers::MetaDataHelper"
      lines << "include Cms::Helpers::NavigationHelper"
      lines << "include Cms::Helpers::ActionView::UrlHelper"
      lines << "include Cms::Helpers::Breadcrumbs"
      lines << "include ActionControllerExtensions::InstanceMethods"
      lines << "include ApplicationHelper"
      lines << "include Cms::Helpers::AnotherFormsHelper"
      lines << "include Cms::Helpers::TagsHelper"

      lines << "reload_rails_admin_config"

      lines << "initialize_locale_links"

      lines_str = lines.map{|line| "\n  " + line }.join("")
      application_controller_path = "app/controllers/application_controller.rb"

      root_without_locale_definition = "\n  def root_without_locale\n    redirect_to root_path(locale: I18n.locale)\n  end\n"
      render_not_found_definition = "\n  def render_not_found\n    render template: \"errors/not_found.html.slim\", status: 404, layout: \"application\"\n  end\n"
      inject_into_class(application_controller_path, ApplicationController, render_not_found_definition )
      if @use_translations
        inject_into_class(application_controller_path, ApplicationController, root_without_locale_definition )
      end
      comment_lines application_controller_path, /protect_from_forgery/
      insert_into_file(application_controller_path, lines_str, after: "class ApplicationController < ActionController::Base\n")
    end

    def init_application_rb
      application_rb_path = "config/application.rb"
      lines = []
      lines << "config.time_zone = 'Kyiv'"
      lines << "config.active_record.default_timezone = :local"
      lines << "config.i18n.available_locales = [#{@locales.map{|l| ":#{l}" }.join(", ")}]"
      lines << "config.i18n.default_locale = :#{@locales.first}"
      lines << 'Rails.application.config.action_mailer.default_url_options = {host: (ENV["#{Rails.env}.host_with_port"] || ENV["#{Rails.env}.host"])}'
      lines << 'config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.yml").to_s]'
      lines << '# ckeditor'
      lines << 'Rails.application.config.assets.precompile += %w(ckeditor/* ckeditor/lang/*)'
      lines << 'config.assets.enabled = true'
      lines << 'config.assets.precompile += Ckeditor.assets'
      lines << 'config.autoload_paths += %W(#{config.root}/app/models/ckeditor)'
      lines << '# file_editor'
      lines << 'config.assets.precompile += %w(fonts/octicons/octicons.woff cms/file_editor.css cms/file_editor.js)'
      lines_str = lines.map{|line| "\n    #{line}" }.join("") + "\n"
      inject_into_file application_rb_path, lines_str, :before => /^  end/
    end

    def init_application_yml
      template "config/application.yml.erb", "config/application.yml"
    end

    def add_forms
      @forms.each do |form_key, form_columns|
        Rails::Generators.invoke("cms:form", [form_key, form_columns])
      end
    end

    def add_controllers

    end
  end
end