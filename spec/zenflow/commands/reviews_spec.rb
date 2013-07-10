require 'spec_helper'

describe Zenflow::Reviews do

  describe "#list" do
    before do
      pull = double
      pull.stub(:[]).with("number").and_return(1)
      pull.stub(:[]).with("head").and_return({ "ref" => "URL" })
      Zenflow::PullRequest.should_receive(:list).and_return([pull])
    end
    it { capture(:stdout) { Zenflow::Reviews.new.invoke(:list) } }
  end

end
