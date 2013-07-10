module QueryInterface
  module Client
    class LazyQuery

      attr_accessor :model, :api_params, :result

      def initialize(model, api_params = nil)
        self.model = model
        self.api_params = {
          conditions: api_params ? api_params[:conditions].dup : {},
          with: api_params ? api_params[:with].dup : [],
          order: api_params ? api_params[:order].dup : [],
        }
        self.result = nil
      end

      def filter(conditions)
        self.copy.tap do |dataset|
          dataset.api_params[:conditions].merge!(conditions)
        end
      end

      def with(*fields)
        self.copy.tap do |dataset|
          dataset.api_params[:with] += fields
        end
      end

      def order(*fields)
        self.copy.tap do |dataset|
          dataset.api_params[:order] = fields
        end
      end

      def copy(options = {})
        self.class.new(self.model, self.api_params)
      end

      def do_collection_query(params={})
        self.model.get_collection(:query, query_data: self.api_params.merge(params))
      end

      def do_resource_query(params = {})
        self.model.get_resource(:query, query_data: self.api_params.merge(params))
      end

      def do_raw_query(params = {})
        self.model.get_raw(:query, query_data: self.api_params.merge(params))
      end

      def first(*args)
        one(:first, *args)
      end

      def last(*args)
        one(:last, *args)
      end

      def evaluate
        self.result ||= self.do_collection_query(mode: :evaluate)
      end

      def paginate(params = {})
        params = {page: 1, per_page: 10, mode: :paginate}.merge(params)
        raw = self.do_raw_query(params)[:parsed_data]
        result = raw[:data]
        objects = result[:objects].map { |h| self.model.new(h) }
        WillPaginate::Collection.create(params[:page], params[:per_page], result[:total]) do |pager|
          pager.replace objects
        end
      end

      def ids
        response = self.do_raw_query(mode: :ids)
        response.try(:[], :data)
      end

      def count
        if self.result
          self.result.count
        else
          r = self.do_raw_query(mode: :count)
          r[:parsed_data][:data][:count]
        end
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
          self.do_resource_query(params.merge(mode: which))
        end
      rescue Faraday::Error::ResourceNotFound
        nil
      end

    end
  end
end
