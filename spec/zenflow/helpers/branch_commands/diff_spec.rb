require 'spec_helper'

module BranchCommandSpecs
  module Diff

    class TestCommand < Zenflow::BranchCommands::Diff
      flow "test"
      branch source: "master"
      branch destination: "production"
      branch deploy: "deploy1"
      branch deploy: "deploy2"
      version :patch
      changelog :rotate
      tag true
    end

    describe "Zenflow::BranchCommands::Diff" do
      before do
        Zenflow.should_receive(:Log).with("Displaying diff with master")
        Zenflow::Shell.should_receive(:[]).with("git difftool master")
      end
      it { TestCommand.new.invoke(:diff) }
    end

  end
end
