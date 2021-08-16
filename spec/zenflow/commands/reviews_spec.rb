require 'spec_helper'

describe Zenflow::Reviews do

  describe "#list" do
    before do
      pull = double
      allow(pull).to receive(:[]).with("number").and_return(1)
      allow(pull).to receive(:[]).with("head").and_return({ "ref" => "URL" })
      expect(Zenflow::PullRequest).to receive(:list).and_return([pull])
    end
    it { capture(:stdout) { Zenflow::Reviews.new.invoke(:list) } }
  end

end
