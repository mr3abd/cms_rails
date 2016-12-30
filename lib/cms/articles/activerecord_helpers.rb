module Cms
  module Articles
    module ActiveRecordExtensions
      module ClassMethods


        def acts_as_article options = {}
          #attr_accessor :acts_as_article_options
          #self.acts_as_article_options = options
          class_variable_set(:@@acts_as_article_options, options)
          if mod = options[:base_articles]
            self.send(:extend, mod)
          end


          if options[:author] != false
            belongs_to :author, class_name: User
            attr_accessible :author
          end

          self.attr_accessible *attribute_names
          initialize_all_attachments = options[:initialize_all_attachments]
          initialize_all_attachments ||= false
          attachment_names = [:avatar]

          if initialize_all_attachments
            attachment_names = paperclip_attachment_names_from_columns
          end

          if attachment_names.try(&:any?)
            attachment_names.each do |attachment_name|
              has_attached_file attachment_name
              do_not_validate_attachment_file_type attachment_name if respond_to?(:do_not_validate_attachment_file_type)
              attr_accessible attachment_name
              allow_delete_attachment attachment_name
            end
          end

          has_seo_tags

          scope :published, -> { where(published: true) }

          if options[:tags]
            acts_as_taggable

            attr_accessible :tag_list
          end

          # setup callbacks

          self.before_validation :initialize_url_fragment
        end

        def acts_as_article_options
          opts = class_variable_get(:@@acts_as_article_options) || {}
        end

        def paperclip_suffixes
          %w(_file_name _content_type _file_size _updated_at)
        end

        def paperclip_attachment_names_from_columns
          return nil unless self.table_exists?


          matched_columns = self.column_names.sort.select{ |c|
            matches = false
            paperclip_suffixes.each do |s|
              res = c.ends_with?(s)
              #next false if !res

              if res
                matches = true
                break
              end
            end

            next matches
          }

          return matched_columns.map{|c|
            c.gsub(/#{paperclip_suffixes.join("|")}/, "")
          }.uniq
        end


      end

      module InstanceMethods
        def initialize_url_fragment
          if self.respond_to?(:url_fragment) && self.respond_to?(:url_fragment=)
            self.url_fragment = self.name.parameterize if self.url_fragment.blank?
          end
        end

        def to_param
          fragment = nil
          if self.respond_to?(:url_fragment) && self.url_fragment.present?
            fragment = self.url_fragment
          end

          fragment ||= self.id.to_s

          return fragment
        end

        def prev(collection, options = {})
          options = _normalize_navigation_options(options)
          ids = collection.map(&:id)
          current_index = ids.index(self.id)
          max_index = ids.count - 1

          indexes = options[:count].times.map do |i|
            prev_index = current_index - i - 1

            if prev_index < 0 && !options[:cycle]
              next nil
            end

            if prev_index < 0
              prev_index = max_index + prev_index + 1
            end

            if prev_index == current_index && options[:except_self]
              next nil
            else
              next prev_index
            end

          end.select(&:present?).uniq

          items = indexes.map{ |index|
            id = ids[index]
            item = self.class.find(id)
          }

          if options[:as_array]
            return items
          else
            if indexes.count == 1
              return items.first
            elsif indexes.count == 0
              return nil
            else
              return items
            end
          end
        end

        def next(collection, options = {})
          options = _normalize_navigation_options(options)
          ids = collection.map(&:id)
          current_index = ids.index(self.id)

          max_index = ids.count - 1
          next_indexes = options[:count].times.map do |i|
            next_index = current_index + i + 1

            if next_index > max_index && !options[:cycle]
              next nil
            end


            if next_index > max_index
              next_index = (max_index - next_index + 1) * -1
            end

            if next_index == current_index && options[:except_self]
              next nil
            else
              next next_index
            end

          end.select(&:present?).uniq

          items = next_indexes.map{ |index|
            id = ids[index]
            item = self.class.find(id)
          }

          if options[:as_array]
            return items
          else
            if next_indexes.count == 1
               return items.first
            elsif next_indexes.count == 0
              return nil
            else
              return items
            end
          end
        end

        def _normalize_navigation_options(options = {})
          if !options[:count]
            options[:as_array] = false if options[:as_array].nil?
          else
            options[:as_array] = true if options[:as_array].nil?
          end
          options[:cycle] = true if options[:cycle].nil?
          options[:count] ||= 1

          options
        end

        def index_of(collection)
          ids = collection.map(&:id)
          ids.index(self.id)
        end

        def first?(collection)
          index_of(collection) == 0
        end

        def last?(collection)
          index_of(collection) + 1 == collection.count
        end

        def initialize_sorting_position
          self.sorting_position ||= self.id
          self.save
        end
      end
    end
  end
end


ActiveRecord::Base.send(:extend, Cms::Articles::ActiveRecordExtensions::ClassMethods)
ActiveRecord::Base.send(:include, Cms::Articles::ActiveRecordExtensions::InstanceMethods)