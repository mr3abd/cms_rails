class Array
  def in_groups(count, allow_nil = false, &block)
    arr = self
    in_groups_of((arr.count.to_f / count).ceil, allow_nil, &block)
  end
end