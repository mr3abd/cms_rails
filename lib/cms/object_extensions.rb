class Module
  # Return any modules we +extend+
  def extended_modules
    (class << self; self end).included_modules
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
end