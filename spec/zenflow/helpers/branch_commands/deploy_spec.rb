require 'spec_helper'

module BranchCommandSpecs
  module Deploy

    class TestCommand < Zenflow::BranchCommands::Deploy
      flow "test"
      branch source: "master"
      branch destination: "production"
      branch deploy: "deploy1"
      branch deploy: "deploy2"
      version :patch
      changelog :rotate
      tag true
    end

    describe "Zenflow::BranchCommands::Deploy" do
      context "when a project is not deployable" do
        before do
          Zenflow::Branch.should_receive(:current).with("test").and_return("new-test-branch")
          Zenflow::Config.should_receive(:[]).with(:deployable).and_return(false)
          Zenflow.should_receive(:Log).with("This project is not deployable right now", color: :red)
        end
        it { expect{TestCommand.new.invoke(:deploy)}.to raise_error(SystemExit) }
      end

      context "without running migrations" do
        before do
          Zenflow::Branch.should_receive(:current).with("test").and_return("new-test-branch")
          Zenflow::Config.should_receive(:[]).with(:deployable).and_return(true)
          Zenflow::Branch.should_receive(:update).with("deploy1")
          Zenflow::Branch.should_receive(:update).with("deploy2")
          Zenflow::Branch.should_receive(:merge).with("test/new-test-branch").twice
          Zenflow.should_receive(:Deploy).with("deploy1", {})
          Zenflow.should_receive(:Deploy).with("deploy2", {})
          Zenflow::Branch.should_receive(:checkout).with("test/new-test-branch")
        end
        it { TestCommand.new.invoke(:deploy) }
      end

      context "when running migrations" do
        before do
          Zenflow::Branch.should_receive(:current).with("test").and_return("new-test-branch")
          Zenflow::Config.should_receive(:[]).with(:deployable).and_return(true)
          Zenflow::Branch.should_receive(:update).with("deploy1")
          Zenflow::Branch.should_receive(:update).with("deploy2")
          Zenflow::Branch.should_receive(:merge).with("test/new-test-branch").twice
          Zenflow.should_receive(:Deploy).with("deploy1", { "migrations" => true })
          Zenflow.should_receive(:Deploy).with("deploy2", { "migrations" => true })
          Zenflow::Branch.should_receive(:checkout).with("test/new-test-branch")
        end
        it { TestCommand.new.invoke(:deploy, [], "migrations" => true) }
      end
    end

  end
end
