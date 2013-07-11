require 'spec_helper'

module BranchCommandSpecs
  module Compare

    class TestCommand < Zenflow::BranchCommands::Compare
      flow "test"
      branch source: "master"
      branch destination: "production"
      branch deploy: "deploy1"
      branch deploy: "deploy2"
      version :patch
      changelog :rotate
      tag true
    end

    describe "Zenflow::BranchCommands::Compare" do
      before do
        Zenflow::Branch.should_receive(:current).with("test").and_return("new-test-branch")
        Zenflow.should_receive(:Log).with("Opening GitHub compare view for master...test/new-test-branch")
        Zenflow::Repo.should_receive(:slug).and_return("test-repo")
        Zenflow::Shell.should_receive(:[]).with("open https://github.com/test-repo/compare/master...test/new-test-branch")
      end
      it { TestCommand.new.invoke(:compare) }
    end

  end
end
