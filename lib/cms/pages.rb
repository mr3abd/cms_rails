module Pages
  class << self
    def method_missing(name, *args, &block)
      normalized_name = name.to_s.camelize

      #if Pages.constants.map(&:to_s).include?(normalized_name)

      #end

      return Pages.const_get(normalized_name).first_or_initialize rescue super(name, *args, &block)


    end

    def create_pages
      Cms.pages_models.map(&:constantize).map{|m|
        obj = m.first || m.new
        if !obj.seo_tags
          obj.build_seo_tags
          obj.seo_tags.page_type = m.name
          obj.save
        end
      }
    end

    def all
      Cms.pages_models.map(&:constantize)
    end

    def all_instances
      Pages.all.map{|c| c.first_or_create }
    end

    def clear_all
      Pages.all_instances.each{|p| p.clear_cache(false) }
    end
  end
end