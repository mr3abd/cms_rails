module ActionDispatch
  module Routing
    class Mapper
      def domains(*args, &block)
        addresses = args.flatten
        constraints(DomainConstraint.new(addresses), &block)
      end
    end
  end
end