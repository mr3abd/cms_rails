class Module
  # Return any modules we +extend+
  def extended_modules
    (class << self; self end).included_modules
  end
end