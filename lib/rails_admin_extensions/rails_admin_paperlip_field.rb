require 'rails_admin/config/fields/types/paperclip'

module RailsAdmin
  module Config
    module Fields
      module Types
        # Field type that supports Paperclip file uploads
        class Paperclip < RailsAdmin::Config::Fields::Types::FileUpload
          def generic_field_help
            str = super
            #size = bindings[:object]
            attachment_definition = abstract_model.model.attachment_definitions[name.to_sym]
            return str if attachment_definition.blank?
            size = Cms.parse_image_size(attachment_definition)

            "#{str} #{size}"
          end
        end
      end
    end
  end
end
