module QueryInterface
  module Client
    class LazyQuery

      attr_accessor :model, :result, :result_model, :transformations

      def initialize(model, transformations=nil, result_model=nil)
        self.model = model
        if transformations
          self.transformations = transformations.map {|item| item.dup}
        else
          self.transformations = []
        end
        self.result = nil
        self.result_model = result_model
      end

      def parse(data)
        (self.result_model ? self.result_model.parse(data) : self.model.parse(data))
      end

      def instantiate(data)
        (self.result_model ? self.result_model.new(data) : self.model.new(data))
      end

      def instantiate_collection(parsed_data)
        (self.result_model ? self.result_model.new_collection(parsed_data) : self.model.new_collection(parsed_data))
      end

      def copy(options = {})
        self.class.new(self.model, self.transformations, self.result_model)
      end

      def add_transformation(type, parameter=nil)
        self.transformations << {transformation: type, parameter: parameter}
      end

      def filter(conditions={})
        self.copy.tap do |query|
          conditions.each do |key, value|
            query.add_transformation(:filter, {field: key, value: value})
          end
        end
      end

      def instance(id)
        self.copy.tap do |query|
          query.add_transformation(:instance, id)
        end
      end

      def context(association, model=nil)
        self.copy.tap do |query|
          query.result_model = (model ? model : association.to_s.singularize.camelize.constantize)
          query.add_transformation(:context, association)
        end
      end

      def with(*fields)
        self.copy.tap do |query|
          fields.each do |field|
            query.add_transformation(:with, field)
          end
        end
      end

      def order(*fields)
        self.copy.tap do |query|
          fields.each do |field|
            query.add_transformation(:order, field)
          end
        end
      end

      def evaluate
        self.result ||= self.do_query()
      end

      def paginate(page: 1, per_page: 10)
        query = self.copy
        query.add_transformation(:paginate, {page: page, per_page: per_page})
        raw = query.do_raw_query()
        result = raw[:parsed_data][:data]
        objects = result[:objects].map { |h| query.instantiate(h) }
        WillPaginate::Collection.create(page, per_page, result[:total]) do |pager|
          pager.replace objects
        end
      end

      def ids
        query = self.copy
        query.add_transformation(:map_ids)
        query.do_raw_query()[:parsed_data][:data]
      end

      def count
        if self.result
          self.result.count
        else
          query = self.copy
          query.add_transformation(:count)
          r = query.do_raw_query()
          r[:parsed_data][:data][:count]
        end
      end

      def do_query
        parsed_data = self.do_raw_query[:parsed_data]
        if parsed_data[:data].is_a?(Array)
          self.instantiate_collection(parsed_data)
        else
          self.instantiate(
            self.parse(parsed_data[:data]).
              merge(_metadata: parsed_data[:metadata], _errors: parsed_data[:errors])
            )
        end
      end

      def do_raw_query
        self.model.get_raw(:query, transformations: self.transformations)
      end

      def first(*args)
        one(:first, *args)
      end

      def last(*args)
        one(:last, *args)
      end

      def to_json(*args)
        evaluate.to_json(*args)
      end

      def method_missing(method_name, *args, &block)
        evaluate.send(method_name, *args, &block)
      end

    protected

      def one(which, params = {})
        if self.result
          self.result.send(which)
        else
          query = self.copy
          query.add_transformation(which)
          query.do_query
        end
      end

    end
  end
end
