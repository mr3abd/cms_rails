require 'rails/generators'
require File.expand_path('../utils', __FILE__)

module Cms
  class PageGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    include Generators::Utils::InstanceMethods

    argument :name, required: true

    def index
      @page_file_name = name.to_s.underscore
      @page_class_name = name.to_s.camelize
      if name.downcase == "home"
        if @use_translations
          @specific_url = '"/#{locale}"'
        else
          @specific_url = '"/"'
        end
      end

      template "models/page.rb.erb", "app/models/pages/#{@page_file_name}.rb"
    end

    private

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