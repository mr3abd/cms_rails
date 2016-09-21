I18n.module_eval do
  def self.translate(*args)
    Cms.t(*args)
  end

  def self.t(*args)
    translate(*args)
  end
end