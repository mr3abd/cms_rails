module Pages
  class << self
    def method_missing(name, *args, &block)
      normalized_name = name.to_s.camelize

      if Pages.constants.map(&:to_s).include?(normalized_name)
        return Pages.const_get(normalized_name).first_or_initialize
      end

      super(name, *args, &block)
    end

    def a

    end
  end
end