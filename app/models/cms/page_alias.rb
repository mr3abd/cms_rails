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

      if respond_to?(:translation_class)
        translation_class.class_eval do
          before_validation :normalize_urls

          def normalize_urls
            self.urls = Cms::PageAlias.normalize_urls_string(self['urls'])

            true
          end
        end
      end
    end
    enumerize :redirect_mode, in: [:redirect_to_home_page, :redirect_to_specified_page], default: :redirect_to_home_page

    boolean_scope :disabled, nil, :enabled
    scope :with_urls, ->(urls = nil) {
      column_name = 'page_alias_translations.urls'
      rel = joins(:translations)
      if urls.nil?
         rel = rel.where("#{column_name} IS NOT NULL AND #{column_name}<>''")
      elsif urls.is_a?(String) || urls.is_a?(Array)
        urls = Array.wrap(urls)

        query_str = urls.map do |url|
          "page_alias_translations.urls LIKE '%#{url}%'"
        end.join(' OR ')

        rel.where(query_str)
      end
    }

    scope :without_urls, ->(urls = nil) {
      column_name = 'page_alias_translations.urls'
      rel = joins(:translations)

      if urls.nil?
        rel = rel.where("#{column_name} IS NULL OR #{column_name}=''")
      elsif urls.is_a?(String) || urls.is_a?(Array)
        urls = Array.wrap(urls)

        query_str = urls.map do |url|
          "page_alias_translations.urls NOT LIKE '%#{url}%'"
        end.join(' AND ')

        rel.where(query_str)
      end
    }

    scope :by_model, ->(*model_class_or_name) do
      model_classes, model_names = Cms::PageAlias.resolve_model_class_names(*model_class_or_name)

      where(page_type: model_names)
    end

    default_scope do
      order('page_aliases.id desc')
    end

    has_link :page

    validate :urls_should_not_be_duplicated

    def urls_should_not_be_duplicated
      # find duplicates in other locales
      duplicates = find_duplicates_in_other_locales
      urls = self.urls
      blocked_urls = get_unavailable_urls(urls)

      if blocked_urls
        blocked_urls.each do |blocked_url|
          errors.add(:blocked_url, "URL '#{blocked_url}' is blocked to avoid infinite redirect loops")
        end
        urls = urls - blocked_urls
      end


      urls.each do |url|
        page_alias = Cms::PageAlias.resolve_page_alias(url, self.id)
        if page_alias
          page_label = ""
          page = page_alias.redirect_page
          pages_namespace_name = page.class.name.split("::")
          pages_namespace_name = pages_namespace_name[0, pages_namespace_name.count - 1].join("::")
          if pages_namespace_name == "Pages"
            page_label = "#{page.name}"
          else
            page_label = "#{page.class.name} ##{page.id}"
          end

          message = "URL '#{url}' already used in Cms::PageAlias ##{page_alias.id}(#{page_label})"
          errors.add(:duplicated_url, message)
        end
      end
    end

    def find_duplicates_in_other_locales(input_locale = nil, input_url = nil)
      urls = self.urls
      uniq_urls = urls.uniq
      duplicates_count = urls.count - uniq_urls.count
      if duplicates_count > 0
        #urls_by_locale = self.urls_by_locale
        duplicates = urls.select{ |url| urls.count(url) > 1 }.uniq
        duplicates.each do |duplicate_url|
          errors.add(:duplicated_url, "URL '#{duplicate_url}' duplicated across translations")
        end
      end

      #

      #urls_by_locale.each do |locale, urls|
      #  if input_locale.to_s == locale.to_s
      #    next
      #  end
      #end
    end

    def self.register_resource_class(klass, association_name = nil)
      var_name = :@@_resource_classes
      resource_classes = self.class_variable_get(var_name) || [] rescue []
      unless resource_classes.include?(klass)
        resource_classes << klass
        self.class_variable_set(var_name, resource_classes)
        if association_name == false
          return
        end
        association_name = klass.name.underscore.split("/").last if association_name.nil?
        self.belongs_to association_name.to_sym, -> { where(page_aliases: {page_type: klass.name}) }, foreign_key: 'page_id'
        self.define_method association_name.to_sym do
          return unless page_type == klass.name
          super
        end
      end
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
          resource_class = resource.is_a?(Cms::Page) ? Cms::Page : resource.class
          exists = Cms::PageAlias.where(page_id: resource.id, page_type: resource_class.name).count > 0
          if !exists
            Cms::PageAlias.create(page_id: resource.id, page_type: resource_class.name)
          end
        end
      end
    end

    def self.resolve_model_class_names(*class_names)
      model_names = []
      model_classes = []
      class_names.flatten.map do |model_class_or_name|
        if model_class_or_name.is_a?(String)
          model = model_class_or_name.constantize
          model_name = model_class_or_name
        elsif model_class_or_name.is_a?(Class)
          model = model_class_or_name
          model_name = model.name
        end

        model_classes << model
        model_names << model_name
      end

      [model_classes, model_names]
    end

    def self.urls_by_page
      current_scope.map do |page_alias|
        page_alias
      end
    end

    def self.resolve_page_alias(input_url, ignore_page_aliases = [])
      rel = Cms::PageAlias
      if ignore_page_aliases.present?
        rel = rel.where.not(page_aliases: { id: ignore_page_aliases })
      end
      page_aliases = rel.enabled.with_urls(input_url).includes(:translations)
      page_aliases.find do |pa|
        urls = pa.urls

        urls.include?(input_url)
      end
    end

    def self.resolve_page_redirect_url(input_url)
      page_alias = resolve_page_alias(input_url)
      if page_alias.nil?
        return nil
      else
        page_alias.resolve_redirect_url(input_url)
      end
    end

    def self.normalize_urls_string(urls)
      if urls.blank?
        return ""
      end

      urls_array = urls.split("\r\n").select(&:present?)
      urls_array.map do |url|
        normalized_url = url.strip
        uri = URI.parse(normalized_url)
        s = uri.path
        if s.present? && !s.start_with?('/')
          s = "/#{s}"
        end

        if s.length > 2 && s.end_with?('/')
          s = s[0, s.length - 1]
        end

        s
      end.select{|url| url.length > 1 }.uniq.join("\r\n")
    end

    def urls
      urls_by_locale.values.flatten
    end

    def urls_by_locale
      entries = translations.map do |page_alias_translation|
        translation_urls = Cms::TextFields.get_line_separated_field_value(page_alias_translation, :urls)
        if translation_urls.present?
          [page_alias_translation.locale.to_sym, translation_urls]
        else
          nil
        end
      end.select{|item| !item.nil? }

      Hash[entries]
    end

    def resolve_redirect_url(input_url)
      locale = resolve_redirect_locale(input_url)

      redirect_url(locale)
    end

    def resolve_redirect_locale(input_url)
      locale = urls_by_locale.keep_if{|locale, urls|
        urls.include?(input_url)
      }.keys.first
    end

    def redirect_url(locale = I18n.locale)
      redirect_page(locale).url(locale)
    end

    def redirect_page(locale = I18n.locale)
      if redirect_mode.to_s == 'redirect_to_home_page'
        return Pages.home
      else
        if !page
          return Pages.home
        end

        if page.respond_to?(:published?)
          if !page.published?
            return Pages.home
          end
        end

        if page.url(locale).present?
          page
        else
          Pages.home
        end
      end
    end

    def get_unavailable_urls(urls = nil)
      all_urls = Cms.config.page_alias_blocked_urls
      if urls.nil?
        all_urls
      else
        urls.select{|url|
          all_urls.index(url)
        }
      end
    end
  end
end