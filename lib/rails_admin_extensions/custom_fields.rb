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
          next ["#{class_name} -> #{name}", val]

        else
          next [(name = p.try(:name); name = p.try(:title) if name.blank?; name = "-" if name.blank?; name) , val]
        end

      }
    end

    def value
      @bindings[:object].send(name).try{|p| "#{p.class.name}##{p.id}" }
    end

    help do
      @bindings[:object].send(name).try{|p| "#{p.class.name}##{p.id}" } || "test"
    end
  end
end