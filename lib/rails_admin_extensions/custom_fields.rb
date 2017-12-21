def linkable_field(scopes = [], name = :linkable, options = {})
  field name, :enum do
    enum do
      # associated_model_config.collect do |config|
      #   [config.label, config.abstract_model.model.name]
      # end
      if scopes.blank?
        return []
      end

      scopes = scopes.map{|s|
        if s.subclass_of?(ActiveRecord::Base)
          s = s.all
          if s.respond_to?(:published)
            s = s.published
          end
        end

        s
      }

      res = scopes.sum.map{|p|
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

      if options[:sort_by_path]
        res = res.sort_by{|item| item.first }
      end

      res
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
      Cms::Watermark::POSITIONS.map{|k| [(I18n.t("rails_admin.watermark_position_field.positions.#{k}", raise: true) rescue k), k] }
    end
  end
end

def js_field(name)
  field name, :code_mirror do
    theme = "night" # night
    mode = 'javascript'

    assets do
      {
          mode: "/assets/codemirror/modes/#{mode}.js",
          theme: "/assets/codemirror/themes/#{theme}.css"
      }
    end

    config do
      {
          mode: mode,
          theme: theme
      }
    end
  end
end

def associated_collection_scope_except_current
  associated_collection_scope do
    id = bindings[:object].try(:id)
    proc do |scope|
      if id
        scope.where.not(id: id)
      else
        scope
      end
    end
  end
end

def scheme_enum_field(name)
  field name, :enum do
    enum do
      [["1 (6 images)", "1"], ["2 (4 images)", "2"], ["3 (5 images)", "3"], ["4 (10 images)", "4"], ["5 (6 images)", "5"], ["6 (1 image)", "6"], ["7 (7 images)", "7"], ["8 (3 images)", "8"]]
    end
  end
end

def translated_field(name, link = false)
  field name do
    def value
      @bindings[:object].send(name)
    end

    pretty_value do
      v = value
      if link
        v = rails_admin_resource_name
        url = Cms.rails_admin_url(@bindings[:object])
        "<a href='#{url}'>#{v}</a>".html_safe
      else
        v = "-" if v.blank?
        v
      end
    end
  end
end