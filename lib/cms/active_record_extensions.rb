
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




      def has_sitemap_record
        has_one :sitemap_record, class_name: "Cms::SitemapElement", as: :page
        accepts_nested_attributes_for :sitemap_record
        attr_accessible :sitemap_record, :sitemap_record_attributes
      end

      def reload_routes
        DynamicRouter.reload
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
        if self._reflections[:html_blocks].nil?
          has_many :html_blocks, class_name: "Cms::HtmlBlock", as: :attachable
        end
        names.each do |name|
          name = name.to_sym

          if !has_html_block_field_name?(name)
            if self.class_variable_defined?(:@@html_field_names)
              html_field_names = self.class_variable_get(:@@html_field_names)
            end
            html_field_names ||= []

            html_field_names << name.to_s
            class_variable_set(:@@html_field_names, html_field_names)
            define_getter = options[:getter] ||= true
            define_setter = options[:setter] ||= true

            has_one name, -> { where(attachable_field_name: name) }, class_name: "Cms::HtmlBlock", as: :attachable, autosave: true
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

      def has_banner

      end

      def html_block_field_names
        return [] if !class_variable_defined?(:@@html_field_names)
        class_variable_get(:@@html_field_names) || []
      end

      def has_html_block_field_name?(name)
        self.class_variable_defined?(:@@html_field_names) && (names = self.class_variable_get(:@@html_field_names)).present? && names.include?(name.to_s)
      end


    end
  end

  def self.create_html_blocks_table
    connection.create_table :html_blocks do |t|
      t.text :content

      t.integer :attachable_id
      t.string :attachable_type
      t.string :attachable_field_name
      t.string :key

    end
  end

  def self.drop_html_blocks_table
    connection.drop_table :html_blocks
  end

  def self.create_seo_tags_table
    connection.create_table :seo_tags do |t|
      t.string :page_type
      t.integer :page_id
      t.string :title
      t.text :keywords
      t.text :description
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
    drop_table :seo_tags
  end

  def self.create_pages_table
    connection.create_table :pages do |t|
      t.string :type
      t.string :name
      t.text :content
      t.string :url

      t.timestamps null: false
    end
  end

  def self.drop_pages_table
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


  def self.connection
    ActiveRecord::Base.connection
  end


  def self.normalize_tables(options = {})
    default_tables = [:form_configs, :pages, :seo_tags, :html_blocks, :sitemap_elements ]
    tables = []
    if options[:only]
      if !options.is_a?(Array)
        options[:only] = [options[:only]]
      end
      tables = options[:only].select{|t| t.to_s.in?(default_tables.map(&:to_s)) }
    elsif options[:except]
      if !options.is_a?(Array)
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