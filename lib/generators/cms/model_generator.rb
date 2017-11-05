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

      attrs = attributes

      puts "name: #{name}"
      puts "attrs: #{attrs.inspect}"

      lines = []
      lines << "class #{@model_class_name} < ActiveRecord::Base"
      lines << "  attr_accessible *attribute_names"

      lines << "end"

      lines_str = lines.join("\n")

      model_file_path = "app/models/#{@model_file_name}.rb"
      create_file model_file_path
      insert_into_file model_file_path, lines_str
    end


  end
end