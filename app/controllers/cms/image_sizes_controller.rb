module Cms
  class ImageSizesController < ApplicationController
    def index
      @models = RailsAdmin.config.included_models.map{|m|
        if m.is_a?(String)
          Object.const_get(m) rescue nil
        else
          m
        end
      }.select{|m| !m.nil? }.select{|m|
        m.respond_to?(:attachment_definitions) && m.attachment_definitions.present?
      }

      #rails_admin_model_groups = RailsAdmin.config.models.map{|m| {model: m.abstract_model.model, navigation_label: m.navigation_label} }
      #filtered_rails_admin_model_groups = rails_admin_model_groups.select{|h| h[:model].in?(models) }
      #mapped_filtered_rails_admin_model_groups = filtered_rails_admin_model_groups.map{|h| h[:model] = h[:model].name; h }.group_by{|h| h[:navigation_label] }
      #render inline: @models.inspect
      render layout: false
    end
  end
end