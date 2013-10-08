require 'spec_helper'


def deep_copy_check(left, right)
  left.each_with_index do |item, idx|
    right[idx].should_not be(item)
  end
end

class Context
end

describe QueryInterface::Client::LazyQuery do
  subject {QueryInterface::Client::LazyQuery}
  let(:model) {double("Dummy Model")}
  let(:transformations) {[{transformation: :filter, parameter: {field: "hase", value: "wuschel"}}]}

  context "construction" do

    it "initializes itself with empty parameters and a supplied model" do
      query = subject.new(model)
      query.transformations.should == []
      query.model.should eq(model)
    end

    it "honors passed transformations params" do
      query = subject.new(model, transformations)
      query.transformations.should eq(transformations)
    end

    it "does not alter the originally passed transformations" do
      query = subject.new(model, transformations)
      deep_copy_check(transformations, query.transformations)
    end
  end

  context "copy" do
    it "provides a copy method cloning transformations onto a new instance" do
      query = subject.new(model, transformations)
      query_copy = query.copy
      query_copy.transformations.should eq(query.transformations)
      deep_copy_check(query_copy.transformations, query.transformations)
    end
  end

  context "filtering" do
    it "should create a new instance with updated transformations" do
      query = subject.new(model)
      query_copy = subject.new(model)
      query.should_receive(:copy).and_return(query_copy)
      query.filter(a: :b)
      query_copy.transformations.should eq([{transformation: :filter, parameter: {field: :a, value: :b}}])
    end
  end

  context "instancing" do
    it "sets the instance parameter" do
      query = subject.new(model)
      query.should_receive(:copy).and_return(query)
      query.instance(5)
      query.transformations.should eq([{transformation: :instance, parameter: 5}])
    end
  end

  context "context" do
    let(:query) {subject.new(model)}
    before do
      query.should_receive(:copy).and_return(query)
      query.context(:context)
    end
    it "should set the correct result model class" do
      query.result_model.should == Context
    end
    it "sets the context parameter" do
      query.transformations.should eq([{transformation: :context, parameter: :context}])
    end
  end

  context "with" do
    it "should create a new instance including additional fields" do
      query = subject.new(model)
      query_copy = subject.new(model)
      query.should_receive(:copy).and_return(query_copy)
      query.with(:c)
      query_copy.transformations.should eq([{transformation: :with, parameter: :c}])
    end
  end

  context "order" do
    it "should create a new instance includuing order fields" do
      query = subject.new(model)
      query_copy = subject.new(model)
      query.should_receive(:copy).and_return(query_copy)
      query.order("-something")
      query_copy.transformations.should eq([{transformation: :order, parameter: "-something"}])
    end
  end

  context "chaining" do
    it "allows chaining transformations in order of appearance" do
      query = subject.new(model)
      query_copy = query.filter(a: :b, c: :d).filter(e: :f).with(:x, :y).instance(12).context(:context)
      query_copy.transformations.should eq(
        [
          {transformation: :filter, parameter: {field: :a, value: :b}},
          {transformation: :filter, parameter: {field: :c, value: :d}},
          {transformation: :filter, parameter: {field: :e, value: :f}},
          {transformation: :with, parameter: :x},
          {transformation: :with, parameter: :y},
          {transformation: :instance, parameter: 12},
          {transformation: :context, parameter: :context}
        ]
      )
    end
  end

  context "first" do
    let(:transformations) {[transformation: :first, parameter: nil]}
    it "gets the first object via do_query" do
      query = subject.new(model)
      query.should_receive(:do_query)
      query.first
      query.transformations.should eq(self.transformations)
    end

    it "uses the cached result" do
      query = subject.new(model)
      query.result = ["a", "b", "c"]
      query.should_not_receive(:do_raw_query)
      query.first.should eq("a")
    end
  end

  context "evaluate" do
    let(:transformations) {[{transformation: :evaluate, parameter: nil}]}
    context "without instance set" do
      before do
        model.should_receive(:get_raw)
        .with(:query, transformations: self.transformations)
        .and_return({parsed_data: {data: ["result object"]}})
        model.stub(:new_collection).and_return(["result object"])
      end

      it "add an evaluation transformation" do
        query = subject.new(model)
        query.evaluate
        query.transformations.should eq(transformations)
      end

      it "gets results via do_query and caches the result" do
        query = subject.new(model)
        query.evaluate.should eq(["result object"])
        query.result.should eq(["result object"])
      end

      it "doesn't query the api twice" do
        query = subject.new(model)
        result = query.evaluate
        result_second = query.evaluate
        result.should be(result_second)
      end
    end
  end

  context "count" do
    let(:transformations) {[{transformation: :count, parameter: nil}]}

    it "adds a count transformation" do
      query = subject.new(model)
      query.should_receive(:do_raw_query).and_return({parsed_data: {data: {count: 42}}})
      query.count.should eq(42)
      query.transformations.should eq(self.transformations)
    end

    it "uses cached result for counting" do
      query = subject.new(model)
      query.result = ["a", "b", "c"]
      query.should_not_receive(:do_raw_query)
      query.count.should eq(3)
    end
  end

  context "paginate" do
    let(:transformations) {[{transformation: :paginate, parameter: {page: 1, per_page: 10}}]}


    it "adds a paginate transformation" do
      query = subject.new(model)
      objects = (1..10).to_a
      model.stub(:new).and_return(*objects)
      query.should_receive(:do_raw_query).and_return({parsed_data: {data: {objects: objects, total: 15}, errors: []}})
      result = query.paginate
      query.transformations.should eq(self.transformations)
      result.should eq(objects)
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

  context "do queries" do
    it "do_raw_query"
    it "do_query"
  end

end
