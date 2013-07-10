require 'spec_helper'

class RMDummyClass
  include QueryInterface::Client::Resource
end

describe QueryInterface::Client::Resource do

  let(:lazy_query) { double("LazyQuery") }
  before(:each) do
    QueryInterface::Client::LazyQuery.stub(new: lazy_query)
  end
  context "class methods" do
    context ".query" do
      it "returns a LazyQuery object" do
        RMDummyClass.query.should eq(lazy_query)
      end
    end
    context ".first" do
      it "queries the query object" do
        args = double("Args")
        lazy_query.should_receive(:order).with('id').and_return(lazy_query)
        lazy_query.should_receive(:first)
        RMDummyClass.first(args)
      end
    end
    context ".last" do
      it "queries the query object" do
        args = double("Args")
        lazy_query.should_receive(:order).with('id').and_return(lazy_query)
        lazy_query.should_receive(:last)
        RMDummyClass.last(args)
      end
    end
  end
end
