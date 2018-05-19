module Cms
  class PageAlias < ActiveRecord::Base
    self.table_name = :page_aliases

    attr_accessible *attribute_names
    extend Enumerize

    def self.include_translations?
      Cms::Config.use_translations && respond_to?(:translates?)
    end

    if include_translations?
      globalize :urls, translation_table_name: :page_alias_translations
    end
    enumerize :redirect_mode, in: [:redirect_to_home_page, :redirect_to_specified_page], default: :redirect_to_home_page

    boolean_scope :disabled, nil, :enabled
    scope :by_model, -> do |model_class_or_name|
      if model_class_or_name.is_a?(String)
        model = model_class_or_name.constantize
        model_name = model_class_or_name
      elsif model_class_or_name.is_a?(Class)
        model = model_class_or_name
        model_name = model.name
      end

      where(page_type: model_name)
    end

    default_scope do
      order('id desc')
    end

    has_link :page

    def self.register_resource_class(klass)
      var_name = :@@_resource_classes
      resource_classes = self.class_variable_get(var_name) || [] rescue []
      resource_classes << klass unless resource_classes.include?(klass)
      self.class_variable_set(var_name, resource_classes)
    end

    def self.registered_resource_classes
      var_name = :@@_resource_classes
      self.class_variable_get(var_name) || [] rescue []
    end

    def self.registered_resource_class?(klass)
      registered_resource_classes.include?(klass)
    end

    def self.resources(filter = true)
      registered_resource_classes.map do |klass|
        rel = klass.all
        if filter
          rel = rel.published if rel.respond_to?(:published)
        end

        rel
      end.flatten
    end

    def self.build_page_alias_for_resources
      resources.each do |resource|
        if !resource.page_alias
          resource.build_page_alias
          Cms::PageAlias.create(page_id: resource.id, page_type: resource.class.name)
        end
      end
    end

  end
end