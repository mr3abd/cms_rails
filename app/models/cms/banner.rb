class Cms::Banner < ActiveRecord::Base
  self.table_name = :banners
  attr_accessible *attribute_names
end
