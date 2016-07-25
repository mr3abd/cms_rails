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
              do_not_validate_attachment_file_type attachment_name
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

        def prev(collection)
          ids = collection.map(&:id)
          current_index = ids.index(self.id)
          prev_index = current_index - 1

          if prev_index < 0
            prev_index = ids.count - 1
          end

          prev_id = ids[prev_index]

          prev_item = Project.find(prev_id)

          prev_item
        end

        def next(collection)
          ids = collection.map(&:id)
          current_index = ids.index(self.id)
          next_index = current_index + 1

          if next_index >= ids.count
            next_index = 0
          end

          next_id = ids[next_index]

          next_item = self.class.find(next_id)

          next_item
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