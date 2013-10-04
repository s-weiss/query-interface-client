module QueryInterface
  module Client
    class LazyQuery

      attr_accessor :model, :api_params, :result, :result_model

      def initialize(model, api_params=nil, result_model=nil)
        self.model = model
        self.api_params = {
          conditions: api_params ? api_params[:conditions].dup : {},
          with: api_params ? api_params[:with].dup : [],
          order: api_params ? api_params[:order].dup : [],
          context: api_params ? api_params[:context] : nil,
          instance: api_params ? api_params[:instance] : nil,
        }
        self.result = nil
        self.result_model = result_model
      end

      def instantiate(data)
        (self.result_model ? self.result_model.new(data) : self.model.new(data))
      end

      def filter(conditions)
        self.copy.tap do |dataset|
          dataset.api_params[:conditions].merge!(conditions)
        end
      end

      def instance(id)
        self.copy.tap do |dataset|
          dataset.api_params[:instance] = id
        end
      end

      def context(association, model=nil)
        self.copy.tap do |dataset|
          dataset.result_model = (model ? model : association.to_s.singularize.camelize.constantize)
          dataset.api_params[:context] = association
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
        self.class.new(self.model, self.api_params, self.result_model)
      end

      def do_collection_query(params={})
        unless self.result_model
          self.model.get_collection(:query, query_data: self.api_params.merge(params))
        else
          raw = self.do_raw_query(params)
          raw[:parsed_data][:data].map do |h|
            self.instantiate(h)
          end
        end
      end

      def do_resource_query(params={})
        raw = self.do_raw_query(params)
        self.result ||= self.instantiate(raw[:parsed_data][:data])
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
        unless self.api_params[:instance] && !self.api_params[:context]
          self.result ||= self.do_collection_query(mode: :evaluate)
        else
          self.do_resource_query(mode: :evaluate)
        end
      end

      def paginate(params = {})
        params = {page: 1, per_page: 10, mode: :paginate}.merge(params)
        raw = self.do_raw_query(params)[:parsed_data]
        result = raw[:data]
        objects = result[:objects].map { |h| self.instantiate(h) }
        WillPaginate::Collection.create(params[:page], params[:per_page], result[:total]) do |pager|
          pager.replace objects
        end
      end

      def ids
        self.do_raw_query(mode: :ids)[:parsed_data][:data]
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
      end

    end
  end
end
