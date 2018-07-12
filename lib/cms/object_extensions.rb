class Module
  # Return any modules we +extend+
  def extended_modules
    (class << self; self end).included_modules
  end

  def safe_include(target, *modules)
    modules.each do |m|
      if !target.included_modules.include?(m)
        target.send :include, m
      end
    end
  end

  def safe_extend(target, *modules)
    modules.each do |m|
      if !target.extended_modules.include?(m)
        target.send :extend, m
      end
    end
  end

  def parent_classes(take_while_not_classes = nil)
    classes = self.ancestors.select{|obj| obj.is_a?(Class) }
    if take_while_not_classes && !take_while_not_classes.respond_to?(:each)
      take_while_not_classes = [take_while_not_classes]
    end

    if take_while_not_classes
      classes = classes.take_while{|c| !take_while_not_classes.include?(c) }
    end

    classes
  end

  def subclass_of?(parent_klass)
    return false if !self.is_a?(Class)

    classes = self.ancestors.select{|obj| obj.is_a?(Class) }
    classes.select do |c|
      res = c == parent_klass
      if res
        break true
      end

      next false
    end
  end
end