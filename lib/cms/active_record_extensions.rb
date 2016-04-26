
module Cms
  module ActiveRecordExtensions
    extend ActiveSupport::Concern

    module ClassMethods

      def has_seo_tags
        has_one :seo_tags, class_name: "Cms::MetaTags", as: :page, autosave: true
        accepts_nested_attributes_for :seo_tags
        attr_accessible :seo_tags, :seo_tags_attributes
      end

      # def has_sitemap_record
      #   has_one :sitemap_record, as: :sitemap_resource
      #   attr_accessible :sitemap_record
      # end




      def has_sitemap_record(options = {})
        defaults = {class: Cms.config.sitemap_element_class}
        options = defaults.merge(options)
        has_one :sitemap_record, class_name: options[:class] , as: :page
        accepts_nested_attributes_for :sitemap_record
        attr_accessible :sitemap_record, :sitemap_record_attributes
      end

      def reload_routes
        DynamicRouter.reload
      end

      def image(name, *args)

        has_attached_file name, *args
        do_not_validate_attachment_file_type name
        attr_accessible name
        allow_delete_attachment name
      end

      def pdf(name = "pdf", *args)
        has_attached_file name, *args
        do_not_validate_attachment_file_type name
        attr_accessible name
        allow_delete_attachment name
      end

      def allow_delete_attachment(*names)
        names.each do |k|
          attr_accessor "delete_#{k}".to_sym
          attr_accessible "delete_#{k}".to_sym

          before_validation { send(k).clear if send("delete_#{k}") == '1' }
        end
      end



      def has_html_block(*names, **options)
        names = [:content] if names.empty?
        options[:class] ||= "Cms::HtmlBlock"
        class_name = options[:class]
        if !class_name.is_a?(String)
          class_name = options[:class].name
        end



        reflection_name = class_name.split("::").last.underscore.pluralize.to_sym
        if self._reflections[class_name].nil?
          has_many reflection_name, class_name: options[:class], as: :attachable
        end
        names.each do |name|
          name = name.to_sym

          if !has_html_block_field_name?(name)
            store_html_field_name(name)
            options[:getter] = true if options[:getter].nil?
            options[:setter] = true if options[:setter].nil?
            define_getter = options[:getter]
            define_setter = options[:setter]

            has_one name, -> { where(attachable_field_name: name) }, class_name: options[:class], as: :attachable, autosave: true
            accepts_nested_attributes_for name
            attr_accessible name, "#{name}_attributes".to_sym


            if define_getter

              self.send :define_method, "#{name}" do |locale = I18n.locale|
                owner = self.association(name).owner
                owner_class = owner.class
                puts "owner_class: #{owner_class.name}"
                puts "owner_id: #{owner.id}"
                puts "owner_field_name: #{name}"
                HtmlBlock.all.where(attachable_type: owner_class.name, attachable_id: owner.id, attachable_field_name: name).first.try(&:content)
              end
            end

            if define_setter
              self.send :define_method, "#{name}=" do |value|
                owner = self.association(name).owner
                owner_class = owner.class
                html_block = HtmlBlock.all.where(attachable_type: owner_class.name, attachable_id: owner.id, attachable_field_name: name).first_or_initialize
                html_block.content = value
                html_block.save
              end
            end


          end
        end
      end

      def has_content_blocks(name = nil, **options)

        multiple = options[:multiple]
        options[:class_name] ||= options[:class] || Cms.config.content_block_class


        multiple = true if multiple.nil?

        reflection_method = :has_one
        reflection_method = :has_many if multiple

        name ||=  multiple ? :content_blocks : :content_block

        return false if self._reflections.keys.include?(name.to_s)

        send reflection_method, name, -> { where(attachable_field_name: name) }, as: :attachable, class_name: options[:class_name], dependent: :destroy, autosave: true

        if !has_content_block_field_name?(name)
          store_content_field_name(name)

          accepts_nested_attributes_for name
          attr_accessible name, "#{name}_attributes".to_sym
        end
      end

      def has_content_block(name = nil, **options)
        options[:multiple] = false
        has_content_blocks(name, options)

        return options
      end



      def has_tags(name = :tags)
        has_many :taggings, -> { where(taggable_field_name: name) }, as: :taggable, class_name: Cms::Tagging, dependent: :destroy, autosave: true
        has_many name, through: :taggings, source: :tag, class_name: Cms::Tag
        ids_field_name = name.to_s.singularize + "_ids"
        attr_accessible name, ids_field_name

        resource_class = self
        resource_name = self.name.underscore.gsub('/', '_')

        association_name = resource_name.pluralize

        Cms::Tag.class_eval do
          has_many association_name.to_sym, through: :taggings, source: :taggable, class_name: resource_class, source_type: resource_class
        end

      end

      def store_field_name(array_name, name)
        if self.class_variable_defined?(array_name)
          html_field_names = self.class_variable_get(:@@html_field_names)
        end
        html_field_names ||= []

        html_field_names << name.to_s
        class_variable_set(:@@html_field_names, html_field_names)
      end

      def define_obj

      end

      def has_obj?(name)

      end

      def html_block_field_names
        return [] if !class_variable_defined?(:@@html_field_names)
        class_variable_get(:@@html_field_names) || []
      end

      def has_html_block_field_name?(name)
        has_block_field_name?(:@@html_field_names, name)
      end

      def store_html_field_name(name)
        store_field_name(:@@html_field_names, name)
      end

      def has_content_block_field_name?(name)
        has_block_field_name?(:@@content_field_names, name)
      end

      def has_block_field_name?(var_name, name)
        self.class_variable_defined?(:"#{var_name}") && (names = self.class_variable_get(:"#{var_name}")).present? && names.include?(name.to_s)
      end

      def store_content_field_name(name)
        store_field_name(:@@content_field_names, name)
      end


    end
  end



  def self.drop_content_blocks_table
    connection.drop_table :content_blocks

    if Cms::ContentBlock.include_translations?
      Cms::ContentBlock.drop_translation_table!
    end
  end

  def self.create_html_blocks_table
    connection.create_table :html_blocks do |t|
      t.string :type
      t.text :content

      t.integer :attachable_id
      t.string :attachable_type
      t.string :attachable_field_name
      t.string :key

    end

    if Cms::HtmlBlock.include_translations?
      Cms::HtmlBlock.initialize_globalize
      Cms::HtmlBlock.create_translation_table!(content: :text)
    end
  end

  def self.drop_html_blocks_table
    connection.drop_table :html_blocks

    if Cms::HtmlBlock.include_translations?
      Cms::HtmlBlock.drop_translation_table!
    end
  end

  def self.create_seo_tags_table
    connection.create_table :seo_tags do |t|
      t.string :page_type
      t.integer :page_id
      t.string :title
      t.text :keywords
      t.text :description
    end

    if Cms::MetaTags.include_translations?
      Cms::MetaTags.initialize_globalize
      Cms::MetaTags.create_translation_table!(title: :string, keywords: :text, description: :text)
    end
  end

  def self.create_sitemap_elements_table
    connection.create_table :sitemap_elements do |t|
      t.string :page_type
      t.integer :page_id

      t.boolean :display_on_sitemap
      t.string :changefreq
      t.float :priority

      t.timestamps null: false
    end
  end

  def self.drop_sitemap_elements_table
    connection.drop_table :sitemap_elements
  end

  def self.drop_seo_tags_table
    connection.drop_table :seo_tags

    if Cms::MetaTags.include_translations?
      Cms::MetaTags.drop_translation_table!
    end
  end

  def self.create_pages_table
    connection.create_table :pages do |t|
      t.string :type
      t.string :name
      t.text :content
      t.string :url

      t.timestamps null: false
    end

    if Cms::Page.include_translations?
      Cms::Page.initialize_globalize
      puts "translated: #{Cms::Page.translated_attribute_names}"
      Cms::Page.create_translation_table!(url: :string)
    end
  end


  def self.create_banner_table(options = {})
    ActiveRecord::Base.create_banner_table(options)
  end



  def self.drop_pages_table
    if Cms.config.use_translations
      Cms::Page.drop_translation_table!
    end

    connection.drop_table :pages

  end


  def self.create_form_configs_table
    connection.create_table Cms::FormConfig.table_name do |t|
      t.string :type
      t.text :email_receivers

      t.timestamps null: false
    end
  end

  def self.drop_form_configs_table
    connection.drop_table :form_configs
  end

  def self.create_tags_table(options = {})
    return if Cms::Tag.table_exists?

    connection.create_table Cms::Tag.table_name do |t|
      t.integer :tagging_id
      t.string :name
      t.string :url_fragment
    end

    Cms::Tag.initialize_globalize
    Cms::Tag.create_translation_table!(name: :string, url_fragment: :string)
  end

  def self.create_taggings_table
    return if Cms::Tagging.table_exists?
    connection.create_table Cms::Tagging.table_name do |t|
      t.integer :taggable_id
      t.string :taggable_type
      t.string :taggable_field_name
      t.integer :tag_id
    end
  end

  def self.drop_tags_table
    Cms::Tag.drop_translation_table!

    connection.drop_table Cms::Tag.table_name


  end

  def self.drop_taggings_table
    connection.drop_table Cms::Tagging.table_name
  end


  def self.connection
    ActiveRecord::Base.connection
  end


  def self.normalize_tables(options = {})

    default_tables = [:form_configs, :pages, :seo_tags, :html_blocks, :sitemap_elements ]
    tables = []
    if options[:only]
      if !options[:only].is_a?(Array)
        options[:only] = [options[:only]]
      end
      tables = options[:only].select{|t| t.to_s.in?(default_tables.map(&:to_s)) }
    elsif options[:except]
      if !options[:except].is_a?(Array)
        options[:except] = [options[:except]]
      end
      tables = default_tables.select{|t| !t.to_s.in?(options[:except].map(&:to_s)) }
    else
      tables = default_tables
    end

    tables
  end

  def self.create_tables(options = {})
    tables = normalize_tables(options)

    if tables.any?
      tables.each do |t|
        puts "create table: #{t}"
        send("create_#{t}_table")
      end
    end
  end

  def self.drop_tables(options = {})
    tables = normalize_tables(options)

    if tables.any?
      tables.each do |t|
        send("drop_#{t}_table")
      end
    end
  end
end

ActiveRecord::Base.send(:include, Cms::ActiveRecordExtensions)