require 'spec_helper'

module BranchCommandSpecs
  module Update

    class TestCommand < Zenflow::BranchCommands::Update
      flow "test"
      branch source: "master"
      branch destination: "production"
      branch deploy: "deploy1"
      branch deploy: "deploy2"
      version :patch
      changelog :rotate
      tag true
    end

    describe "Zenflow::BranchCommands::Update" do
      before do
        Zenflow::Branch.should_receive(:current).with("test").and_return("new-test-branch")
        Zenflow::Branch.should_receive(:update).with("master")
        Zenflow::Branch.should_receive(:checkout).with("test/new-test-branch")
        Zenflow::Branch.should_receive(:merge).with("master")
      end
      it { TestCommand.new.invoke(:update) }
    end

  end
end
