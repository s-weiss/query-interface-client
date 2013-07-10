module QueryInterface::Client
  module Resource

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def first(*args)
        self.query.order('id').first
      end

      def last(*args)
        self.query.order('id').last
      end

      def query
        LazyQuery.new(self)
      end
    end

  end
end
