Dir[Rails.root.join("lib/**/*.rb").to_s].each do |f|
  require f
end