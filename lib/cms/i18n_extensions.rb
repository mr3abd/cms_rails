I18n.module_eval do
  def self.translate(*args)
    puts "test"
    Cms.t(*args)
  end
end