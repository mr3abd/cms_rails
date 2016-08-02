class ActiveRecord::ConnectionAdapters::Table

  def linkable(*args)
    options = args.extract_options!
    name = args[0]
    name = :linkable if name.blank?
    #options.reverse_merge!({ precision: 8, scale: 2 })
    #column_names = args
    column("#{name}_id", :integer, options)
    column("#{name}_type", :string, options)
  end

end