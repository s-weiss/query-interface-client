require 'spec_helper'


def deep_copy_check(left, right)
  left.should_not be(right)
  [:conditions, :with, :order].each do |key|
    left[key].should_not be(right[key])
  end
end

describe QueryInterface::Client::LazyQuery do
  subject {QueryInterface::Client::LazyQuery}
  let(:model) {double("Dummy Model")}
  let(:default_params) { {conditions: {}, with: [], order: []} }

  context "construction" do
    let(:api_params) do
      {conditions: {field: 'value'}, with: [:inclusion], order: ["-something"]}
    end

    it "initializes itself with empty parameters and a supplied model" do
      query = subject.new(model)
      query.api_params.should == {conditions: {}, with: [], order: []}
      query.model.should eq(model)
    end

    it "honors passed api params" do
      query = subject.new(model, api_params)
      query.api_params.should == api_params
    end

    it "does not alter the originally passed api_params" do
      query = subject.new(model, api_params)
      deep_copy_check(api_params, query.api_params)
    end
  end

  context "copy" do
    let(:api_params) do
      {conditions: {field: 'value'}, with: [:inclusion], order: ["-something"]}
    end
    it "provides a copy method cloning api_params onto a new instance" do
      query = subject.new(model, api_params)
      query_copy = query.copy
      query_copy.api_params.should eq(query.api_params)
      deep_copy_check(query_copy.api_params, query.api_params)
    end
  end

  context "filtering" do
    it "should create a new instance with updated api_params" do
      query = subject.new(model)
      query_copy = subject.new(model)
      query.should_receive(:copy).and_return(query_copy)
      query.filter(a: :b)
      query_copy.api_params[:conditions].should eq({a: :b})
    end
  end

  context "with" do
    it "should create a new instance including additional fields" do
      query = subject.new(model)
      query_copy = subject.new(model)
      query.should_receive(:copy).and_return(query_copy)
      query.with(:c)
      query_copy.api_params[:with].should eq([:c])
    end
  end

  context "order" do
    it "should create a new instance includuing order fields" do
      query = subject.new(model)
      query_copy = subject.new(model)
      query.should_receive(:copy).and_return(query_copy)
      query.order("-something")
      query_copy.api_params[:order].should eq(["-something"])
    end
  end

  context "chaining" do
    it "allows chaining of filter and with" do
      query = subject.new(model)
      query_copy = query.filter(a: :b).filter(c: :d).with(:e).with(:f, :g)
      query_copy.api_params[:conditions].should eq({a: :b, c: :d})
      query_copy.api_params[:with].should eq([:e, :f, :g])
    end

    it "calling order multiple times overwrites" do
      query = subject.new(model)
      query_copy = query.order("-something").order("now really")
      query_copy.api_params[:order].should eq(["now really"])
    end
  end

  context "first" do
    it "gets the first object via do_query" do
      query = subject.new(model)
      model.should_receive(:get_resource)
        .with(:query, query_data: default_params.merge(mode: :first))
        .and_return("result object")
      query.first.should eq("result object")
    end

    it "uses the cached result" do
      query = subject.new(model)
      query.result = ["a", "b", "c"]
      query.should_not_receive(:do_query)
      query.first.should eq("a")
    end
  end

  context "evaluate" do
    it "gets results via do_query and caches the result" do
      query = subject.new(model)
      model.should_receive(:get_collection)
        .with(:query, query_data: default_params.merge(mode: :evaluate))
        .and_return(["result object"])
      query.evaluate.should eq(["result object"])
      query.result.should eq(["result object"])
    end

    it "doesn't query the api twice" do
      query = subject.new(model)
      model.should_receive(:get_collection)
        .with(:query, query_data: default_params.merge(mode: :evaluate))
        .and_return(["result object"])
      result = query.evaluate
      result_second = query.evaluate
      result.should be(result_second)
    end
  end

  context "count" do
    it "gets the count via do_query" do
      query = subject.new(model)
      model.should_receive(:get_raw).with(:query, query_data: default_params.merge(mode: :count))
      .and_return({parsed_data: {data: {count: 42}}})
      query.count.should eq(42)
    end

    it "uses cached result for counting" do
      query = subject.new(model)
      query.result = ["a", "b", "c"]
      query.should_not_receive(:do_query)
      query.count.should eq(3)
    end
  end

  context "paginate" do
    it "paginates results" do
      query = subject.new(model)
      objects = (1..10).to_a
      model.should_receive(:get_raw).with(:query, query_data: default_params.merge({mode: :paginate, page: 1, per_page: 10})).and_return({parsed_data: {data: {objects: objects, total: 15}, errors: []}})
      objects.should_receive(:map).and_return(objects)
      result = query.paginate(page: 1, per_page: 10)
      result.should eq((1..10).to_a)
      result.is_a?(WillPaginate::Collection)
      result.total_entries.should eq(15)
    end
  end

  context "method_missing" do
    it "delegates unknown methods to the result of evaluate" do
      query = subject.new(model)
      result = double("result")
      query.should_receive(:evaluate).and_return(result)
      result.should_receive(:frobnicate!).with("uargh!")
      query.frobnicate!("uargh!")
    end
  end

end
