module ActionDispatch
  module Routing
    class Mapper
      def domains(*args, &block)
        addresses = args.flatten
        constraints(DomainConstraint.new(addresses), &block)
      end

      def domain(*args, &block)
        domains(*args, &block)
      end

      def hosts(*args, &block)
        addresses = args.flatten
        constraints(HostConstraint.new(addresses), &block)
      end

      def host(*args, &block)
        hosts(*args, &block)
      end
    end
  end
end