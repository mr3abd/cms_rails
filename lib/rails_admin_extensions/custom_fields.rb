def linkable_field(models = [], name = :linkable)
  field :linkable, :enum do
    enum do
      # associated_model_config.collect do |config|
      #   [config.label, config.abstract_model.model.name]
      # end
      if models.blank?
        return []
      end

      models.map(&:all).sum.map{|p|
        val = "#{p.class.name}##{p.id}"
        if p.respond_to?(:linkable_path)
          name = p.name
          name = "##{p.id}" if name.blank?
          class_name = p.class.name
          full_name = p.linkable_path
          full_name = "#{class_name} -> #{name}" if full_name.blank?
          next [full_name, val]

        else
          next [(name = p.try(:name); name = p.try(:title) if name.blank?; name = "-" if name.blank?; name) , val]
        end

      }
    end

    def value
      @bindings[:object].send(name).try{|p| "#{p.class.name}##{p.id}" }
    end

    # help do
    #   name
    #   @bindings[:object].send(name).try{|p| "#{p.class.name}##{p.id}" } || "test"
    # end
  end
end

def svg_icon_pretty_value
  pretty_value do
    if value.presence
      v = bindings[:view]
      url = resource_url
      if image
        thumb_url = resource_url(thumb_method)
        image_html = v.image_tag(thumb_url, class: 'img-thumbnail', style: "max-width: 100px")
        url != thumb_url ? v.link_to(image_html, url, target: '_blank') : image_html
      else
        v.link_to(nil, url, target: '_blank')
      end
    end
  end
end

def watermark_position_field(name)
  field "#{name}_watermark_position", :enum do
    #help do
    #  I18n.t("rails_admin.watermark_position_field.help")
    #end

    enum do
      ["NorthWest", "North", "NorthEast", "West", "Center", "East", "SouthWest", "South", "SouthEast"].map{|k| [(I18n.t("rails_admin.watermark_position_field.positions.#{k}", raise: true) rescue k), k] }
    end
  end
end