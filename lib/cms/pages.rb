module Pages
  class << self
    def method_missing(name, *args, &block)
      normalized_name = name.to_s.camelize

      if Pages.constants.map(&:to_s).include?(normalized_name)
        return Pages.const_get(normalized_name).first_or_initialize
      end

      super(name, *args, &block)
    end

    def create_pages
      Pages.all.map(&:first_or_create)
    end

    def all
      Pages.constants.map do |const|
        Pages.const_get(const)
      end
    end

    def all_instances
      Pages.all.map{|c| c.first_or_create }
    end

    def clear_all
      Pages.all_instances.each{|p| p.clear_cache(false) }
    end
  end
end