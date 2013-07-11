require 'spec_helper'

module BranchCommandSpecs
  module Abort

    class TestCommand < Zenflow::BranchCommands::Abort
      flow "test"
      branch source: "master"
      branch destination: "production"
      branch deploy: "deploy1"
      branch deploy: "deploy2"
      version :patch
      changelog :rotate
      tag true
    end

    describe "Zenflow::BranchCommands::Abort" do
      before { Zenflow::Branch.should_receive(:current).with("test").and_return("new-test-branch") }

      context "when online" do
        before do
          Zenflow::Branch.should_receive(:delete_remote).with("test/new-test-branch")
          Zenflow::Branch.should_receive(:delete_local).with("test/new-test-branch", force: true)
        end
        it { TestCommand.new.invoke(:abort) }
      end

      context "when offline" do
        before do
          Zenflow::Branch.should_receive(:delete_local).with("test/new-test-branch", force: true)
        end
        it { TestCommand.new.invoke(:abort, [], offline: true) }
      end
    end

  end
end
