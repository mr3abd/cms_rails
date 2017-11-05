require 'rails/generators'
require File.expand_path('../utils', __FILE__)

module Cms
  class ModelGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    include Generators::Utils::InstanceMethods

    argument :name, required: true
    argument :attributes, :type => :array, :default => [], :banner => "field[:type][:index] field[:type][:index]"
    class_option :use_translations, type: :boolean, default: true


    def index
      @model_file_name = name.to_s.underscore
      @model_class_name = name.to_s.camelize
      @migration_file_name = "create_#{name.to_s.underscore.pluralize}"
      @migration_class_name = "Create#{name.to_s.camelize.pluralize}"
      @table_name = name.to_s.underscore.pluralize

      attrs = attributes

      puts "name: #{name}"
      puts "attrs: #{attrs.inspect}"

      lines = []
      lines << "class #{@model_class_name} < ActiveRecord::Base"
      lines << "  attr_accessible *attribute_names"

      lines << "end"

      lines_str = lines.join("\n")

      model_file_path = "app/models/#{@model_file_name}.rb"
      create_file model_file_path, lines_str

      create_model_migration

    end

    private

    def default_attributes
      {
          name: { type: "string", translates: true},
          url_fragment: { type: "string", translates: true },
          content: {type: "text", translates: true},
          published: {type: "boolean"},
          sorting_position: {type: "integer"},
          short_description: {type: "text"},
          image: {type: "image"},
          avatar: {type: "image"},
          release_date: {type: "date"}
      }
    end

    def column_type_aliases
      {
          bool: "boolean",
          int: "integer",
          image: "attachment",
          dt: "datetime"
      }
    end

    def compute_attributes

    end

    def compute_migration_config

    end

    def compute_model

    end

    def create_model_migration
      @migration_code = ""
      #migration_from_string migration_content, "db/migrate/#{@migration_file_name}.rb", migration_version: migration_version

      migration_template "migrations/create_model.rb.erb", "db/migrate/create_#{@table_name}.rb", migration_version: migration_version
    end

    def migration_version
      "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
    end

  end
end