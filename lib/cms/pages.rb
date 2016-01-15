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
      Pages.constants.each do |const|
        Pages.const_get(const).first_or_create
      end
    end

    def a

    end
  end
end