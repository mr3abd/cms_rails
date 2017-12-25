require 'cms/standard_library_extensions/array'
require 'cms/standard_library_extensions/hash'
require 'cms/protected_attributes'
require "cms/engine"
require "cms/version"
require 'rails_admin'
require 'cms/config' if defined?(RailsAdmin)
require 'cms/object_extensions'
require 'cms/utils'
require 'cms/active_record_extensions'
require 'cms/action_mailer_extensions'
require 'cms/migration_extensions'
require 'cms/activerecord_migration_columns'
require 'cms/activerecord_migration_methods'

#require 'cms/page'
require 'cms/pages'
require 'cms/json_data'
#require 'cms/meta_tags'
#require 'cms/sitemap_record'
#require 'cms/html_block'
#require 'cms/keyed_html_block'
#require 'cms/banner'
#require 'cms/form_config'

require 'cms/caching'
require 'cms/helpers/cache_naming_helper'
require 'cms/watermark'

require 'cms/helpers/pages_helper'
require 'cms/helpers/meta_data_helper'
require 'cms/helpers/navigation_helper'
require 'cms/helpers/action_view_url_helper'
require 'cms/helpers/action_view_cache_helper'
require 'cms/helpers/image_helper'
require 'cms/helpers/url_helper'
require 'cms/helpers/forms_helper'
require 'cms/helpers/another_forms_helper'
require 'cms/helpers/translation_helper'
require 'cms/helpers/breadcrumbs'
require 'cms/helpers/pagination_helper'
require 'cms/helpers/social_helper'
require 'cms/helpers/tags_helper'
require 'cms/helpers/site_data_helper'
require 'cms/helpers/date_helper'
require 'cms/helpers/asset_helper'
require 'cms/helpers/pretty_count'

require 'cms/app_router'
require 'cms/page_url_helpers'
require 'cms/resource_navigation'
require 'cms/human_attribute_name'

require 'cms/activerecord_errors'

require 'cms/notifier'
require 'cms/form_attributes_helper'



require "cms/active_record_helpers"

require 'cms/text_fields'
require 'cms/pricing'

if defined?(Paperclip)
  require 'cms/paperclip_extension'
end
require 'cms/globalize_extension'

require 'cms/articles/activerecord_migrations'
require 'cms/articles/activerecord_helpers'

require 'cms/banners/activerecord_helpers'
require 'cms/banners/activerecord_migrations'
require 'cms/banners/owner_methods'

require 'cms/content_blocks/activerecord_helpers'
require 'cms/content_blocks/activerecord_migrations'
#require 'cms/banners/owner_methods'

require 'cms/ecommerce'

if defined?(RailsAdmin)
  require 'rails_admin_extensions/config'
  require 'rails_admin_extensions/custom_fields'
  require 'rails_admin_extensions/rails_admin_paperlip_field'
  require 'rails_admin_extensions/rails_admin_props'
  require 'rails_admin_extensions/rails_admin_root_clear_cache'
  require 'rails_admin_extensions/rails_admin_model'
end


require 'cms/router_extensions/domain_constraint'
require 'cms/router_extensions/host_constraint'
require 'cms/router_extensions/mapper'
require 'cms/localized_routes/url_helper'

require 'cms/action_controller_extensions'

require 'cms/compression_config'

require 'cms/shortcuts'
require 'cms/texts_updater'
require 'cms/db_changes'

require 'cms/assets_precompile/asset_logger'
require 'cms/assets_precompile/sprockets_extension'

#require 'cms/i18n_extensions'

module Cms
  class << self
    include ActionControllerExtensions::InstanceMethods

    def get_models(path, module_name)
      Dir[Rails.root.join(path)].map{|p| filename = File.basename(p, ".rb"); "#{module_name}::" + filename.camelize }
    end

    def pages_models
      get_models("app/models/pages/*", "Pages")
    end

    def form_configs_models
      get_models("app/models/form_configs/*", "FormConfigs")
    end

    def all_models(with_images = false, exclude_children = false)
      models_root = Rails.root.join("app/models/").to_s
      models = Dir["#{models_root}**/*"].map{|p|
        rel_path = p[models_root.length, p.length];
        file_name_parts = rel_path.split("/");
        file_name_parts[file_name_parts.length - 1] = file_name_parts.last.gsub(/\.rb\Z/, "");
        full_class_name = file_name_parts.map{|part| part.camelize }.join("::");
        Object.const_get(full_class_name) rescue nil }.select{|item| !item.nil? }
      if with_images
        models = models.select{|m|m.respond_to?(:attachment_definitions) && m.attachment_definitions.present?}
      end

      if exclude_children
        models = models.reject{|m| models.include?(m.superclass) }
      end

      models
    end

    def reprocess_images(start_from_model = nil, start_from_id = nil)
      started_from_model = false
      all_models(true, true).each do |m|
        if start_from_model
          if !started_from_model
            if (start_from_model.is_a?(String) && m.name == start_from_model) || (start_from_model.is_a?(Class) && m == start_from_model)
              started_from_model = true
            else
              next
            end
          end
        end
        attachment_keys = m.attachment_definitions.keys
        puts "="*30
        puts "reprocess #{m.name}"
        puts "="*30
        instances = start_from_id && (start_from_model && start_from_model == m || start_from_model == m.name) ? m.where("id > ?", start_from_id) : m.all
        instances.each do |model_instance|
          puts "-"*20
          puts "#{m.name}##{model_instance.id}"
          puts "-"*20
          attachment_keys.each do |k|
            attachment = model_instance.send(k)
            if attachment.exists? && attachment.styles.present?
              begin
                attachment.reprocess!
              rescue
                sleep(10)
                puts "sleep for 10 seconds"
                begin
                  attachment.reprocess!
                rescue
                  next
                end
              end
            end
          end

        end
      end
    end

    def images_count
      total = 0
      total_by_style_count = 0
      all_models(true, true).each do |m|
        attachment_keys = m.attachment_definitions.keys

        m.all.each do |model_instance|
          attachment_keys.each do |k|
            attachment = model_instance.send(k)
            if attachment.exists? && attachment.styles.present?
              total += 1
              total_by_style_count += attachment.styles.keys.count
            end
          end
        end
      end

      puts "total images: #{total}"
      puts "total images by style: #{total_by_style_count}"
    end

    def templates_models
      Dir[Rails.root.join("app/models/templates/*")].map{|p| filename = File.basename(p, ".rb"); "Templates::" + filename.camelize }
    end

    def config(&block)
      config_class = Cms::Config
      if block_given?
        config_class.instance_eval(&block)
      end

      return config_class
    end

    def configure_rails_admin(config)
      models = [Cms::MetaTags]
      config.include_pages_models
      config.include_models(*models)

      models.each do |m|

        m.configure_rails_admin(config)
      end

      if Cms.config.use_translations && Cms::Page.respond_to?(:translation_class)
        config.model Cms::Page.translation_class do
          visible false
        end
      end
    end

    def custom_t(*args)
      text_model = Text rescue Cms::Text rescue nil
      str = nil
      str = text_model.t(*args) if text_model
      #options = args.extract_options!



      keys = args.take_while{|a| a.is_a?(String) || a.is_a?(Symbol) }
      hashes = args.take_while{|a| a.is_a?(Hash); }
      options = hashes.last || {}
      if hashes.count > 1
        params = hashes.first
      else
        params = {}
      end

      key = keys.first
      next_keys = keys[1, keys.length - 1]
      i18n_args = [key, options.merge({raise: true}), params]


      #return ""

      if str.blank?
        if options.nil? || !options.is_a?(Hash)
          options = {}
        end



        begin
          str = I18n.t(*i18n_args)
        rescue
          if text_model
            ignore_scopes = ["activerecord", "rails_admin", "admin", "page_titles"]
            if !key.to_s.split(".").first.in?(ignore_scopes)
              text_model.create(key: key, generated: true) rescue nil
              text_model.load_translations(true)
            end
          end
          next_key_args = next_keys + [params, options]
          str = t(*next_key_args) if str.blank? && next_keys.any?
          str = key.split(".").last.to_s.humanize if str.blank?
        end
      end








      str.to_s.html_safe
    end

    def find_translation_in_pages(*args)
      @t_page_classes ||= Hash[Pages.all_instances.select{|c| c.try(:page_info).present? }.map{|p| c = p.class; pic = c.page_info_class; [c.name.split("::").last.underscore, {attribute_names: pic.attribute_names, page_info: p.page_info, page: p}] }] rescue nil
      res = nil
      if @t_page_classes.try(:any?)
        args.take_while{|a| a.is_a?(String) || a.is_a?(Symbol) }.each do |str|
          key_parts = str.split(".")
          if key_parts.length == 2 && (page_hash = @t_page_classes[key_parts.first]) && page_hash[:attribute_names].include?(key_parts[1])
            res = page_hash[:page].try(key_parts[1])
            res = page_hash[:page_info].try(key_parts[1]) if res.blank?
          end

          return res if res.present?
        end
      end

      nil
    end

    def t(*args)
      res = find_translation_in_pages(*args)
      if res.present?
        return res
      end

      keys = args.take_while{|a| a.is_a?(Symbol) || a.is_a?(String) || a.is_a?(Array) }.flatten
      options = args.last.is_a?(Hash) ? args.last : {}
      text_model = Text rescue Cms::Text rescue nil
      result = text_model.t(*args) if text_model
      i18n_args = [keys.last, options.merge({raise: true})]
      if result.blank?
        begin
          result = I18n.t(*i18n_args)
        rescue
          if text_model
            ignore_scopes = ["activerecord", "rails_admin", "admin", "page_titles"]
            keys.each do |key|
              if !key.to_s.split(".").first.in?(ignore_scopes)
                text_model.create(key: key, generated: true) rescue nil
              end
            end

            text_model.load_translations(true)
          end
          #next_key_args = next_keys + [params, options]
          #result = t(*next_key_args) if str.blank? && next_keys.any?
          result = keys.last.split(".").last.to_s.humanize if result.blank?
        end
      end

      result.to_s.html_safe
    end

    def with_locales(*locales, &block)
      locales = Cms.config.provided_locales if locales.first.nil? || locales.first == :all
      locales.flatten!
      if block_given?
        prev_locales = self.locales
        class_variable_set(:@@_with_locale, locales)
        block.call
        class_variable_set(:@@_with_locale, prev_locales)
      else
        class_variable_set(:@@_with_locale, locales)
      end


    end

    def locales
      val = (class_variable_get(:@@_with_locale) rescue nil)
      val = [val] if !val.is_a?(Array)
      val = val.select{|v| v.present? && Cms.config.provided_locales.map(&:to_s).include?(v.to_s) }
      val = Cms.config.clear_cache_for_locales if val.blank?
      val = [val] if !val.is_a?(Array)

      val
    end

    def url_helpers
      @_url_helpers ||= Rails.application.routes.url_helpers
    end

    def generateHash(length, allow_special_chars = true, allow_numbers = true, allow_upper_case_letters = true, allow_lower_case_letters = true)
      special_chars = "_#"
      numbers = "0123456789"
      lower_case_letters = "abcdefghijklmnopqrstuvwxyz"
      upper_case_letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      symbols_str = ""
      if allow_special_chars
        symbols_str += special_chars
      end

      if allow_numbers
        symbols_str += numbers
      end

      if allow_upper_case_letters
        symbols_str += upper_case_letters
      end

      if allow_lower_case_letters
        symbols_str += lower_case_letters
      end


      symbols = symbols_str.split("")
      length.times.map{
        symbols.sample
      }.join("")
    end

    def parse_image_size(attachment_definition)
      styles = attachment_definition[:styles]
      if styles.try(:any?)
        size = styles.map{|k, v|
          if v.is_a?(Hash)
            if v[:geometry].present?
              geometry = v[:geometry]
            else
              next nil
            end
          else
            geometry = v;
          end

          w, h = geometry.split("x");

          w = w.to_i;
          #fit_size = h.end_with?("#");
          h = h.to_i;
          square = w * h;
          [k, v, square]
        }.select{|a| !a.nil? }.max_by{|a| a[2] }[1]
      else
        size = ""
      end

      size
    end

    def copy_data_to_translations(models = :all, locales = nil)
      return if models.blank?
      if models == :all
        models = Cms.all_models
      end

      locales = I18n.locale if locales.blank?
      locales = [locales] if !locales.is_a?(Array)
      models = [models] if !models.is_a?(Array)
      models = models.select{|m| m.respond_to?(:globalize_attributes) && m.globalize_attributes.present? }
      models.each do |model|
        attr_names = model.translated_attribute_names
        model.all.each do |model_instance|
          locales.each do |locale|
            t = model_instance.translations_by_locale[locale] || model_instance.translations.new(locale: locale)
            attr_names.each do |attr_name|
              if t.send(attr_name).blank?
                t.send("#{attr_name}=", model_instance[attr_name.to_s])
              end
            end

            t.save
          end
        end
      end
    end

    def rails_admin_url(resource_or_options = nil, options = {})
      resource = resource_or_options
      if resource.is_a?(Hash)
        options = resource
        resource = nil
      end
      admin_root = Cms.url_helpers.rails_admin_path
      if resource
        resource_class = options[:class].is_a?(Class) ? options[:class] : resource.class
        resource_class_name_str = resource_class.name.underscore.gsub("/", "~")
        "#{admin_root}/#{resource_class_name_str}/#{resource.id}/edit"
      else
        admin_root
      end
    end

    def rails_admin_resource_name(resource)
      if resource.nil?
        "-"
      else
        name = resource.try(:name)
        if name.blank?
          name = "#{resource.class.name} ##{resource.id}"
        end

        name
      end
    end
  end
end

include_caching_to_models = true
# if include_caching_to_models
#   c = ActiveRecord::Base
#   c.send :include, Cms::PageUrlHelpers
#   c.send :extend, Cms::Caching::ClassMethods
#   c.send :include, Cms::Caching::InstanceMethods
# end

