module Cms
  module Watermark
    POSITIONS = ["NorthWest", "North", "NorthEast", "West", "Center", "East", "SouthWest", "South", "SouthEast"]
    module ActiveRecordExtension
      module ClassMethods
        def enumerize_watermark_position(name)
          enumerize :"#{name}_watermark_position", in: Cms::Watermark::POSITIONS, default: "SouthEast"
        end
      end
    end
  end
end

ActiveRecord::Base.send(:extend, Cms::Watermark::ActiveRecordExtension::ClassMethods)