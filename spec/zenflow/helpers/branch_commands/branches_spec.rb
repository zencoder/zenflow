require 'spec_helper'

module BranchCommandSpecs
  module Branches

    class TestCommand < Zenflow::BranchCommands::Branches
      flow "test"
      branch source: "master"
      branch destination: "production"
      branch deploy: "deploy1"
      branch deploy: "deploy2"
      version :patch
      changelog :rotate
      tag true
    end

    describe "Zenflow::BranchCommands::Branches" do
      before do
        Zenflow.should_receive(:Log).with("Available test branches:")
        Zenflow::Branch.should_receive(:list).with("test").and_return(["YES"])
        Zenflow.should_receive(:Log).with("* YES", indent: true, color: false)
      end
      it { TestCommand.new.invoke(:branches) }

    end

  end
end
