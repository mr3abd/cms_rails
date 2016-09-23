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
            styles = attachment_definition[:styles]
            if styles.try(:any?)
              size = styles.map{|k, v| w, h = v.split("x"); w = w.to_i; fit_size = h.end_with?("#"); h = h.to_i; square = w * h; [k, v, square] }.max_by{|a| a[2] }[1]
            else
              size = ""
            end

            "#{str} #{size}"
          end
        end
      end
    end
  end
end
