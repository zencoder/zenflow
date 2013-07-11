require 'spec_helper'

module BranchCommandSpecs
  module Finish

    class TestCommand < Zenflow::BranchCommands::Finish
      flow "test"
      branch source: "master"
      branch destination: "production"
      branch deploy: "deploy1"
      branch deploy: "deploy2"
      version :patch
      changelog :rotate
      tag true
    end

    describe "Zenflow::BranchCommands::Finish" do
      before do
        Zenflow::Branch.should_receive(:current).with("test").and_return("new-test-branch")
      end

      context "with confirmations" do
        it "without deployment to staging" do
          Zenflow::Config.should_receive(:[]).with(:confirm_staging).and_return(true)
          Zenflow.should_receive(:Ask).with("Has this been tested in a staging environment first?", options: ["Y", "n"], default: "Y").and_return("n")
          Zenflow.should_receive(:Log).with("Sorry, deploy to a staging environment first", color: :red)
          expect{TestCommand.new.invoke(:finish)}.to raise_error(SystemExit)
        end

        it "without review" do
          Zenflow::Config.should_receive(:[]).with(:confirm_staging).and_return(true)
          Zenflow::Config.should_receive(:[]).with(:confirm_review).and_return(true)
          Zenflow.should_receive(:Ask).with("Has this been tested in a staging environment first?", options: ["Y", "n"], default: "Y").and_return("y")
          Zenflow.should_receive(:Ask).with("Has this been code reviewed yet?", options: ["Y", "n"], default: "Y").and_return("n")
          Zenflow.should_receive(:Log).with("Please have someone look at this first", color: :red)
          expect{TestCommand.new.invoke(:finish)}.to raise_error(SystemExit)
        end
      end

      context "without confirmations" do
        before do
          Zenflow::Config.should_receive(:[]).with(:confirm_staging).and_return(false)
          Zenflow::Config.should_receive(:[]).with(:confirm_review).and_return(false)
        end

        context "when online" do
          before do
            Zenflow::Branch.should_receive(:update).with("production")
            Zenflow::Branch.should_receive(:checkout).with("test/new-test-branch")
            Zenflow::Branch.should_receive(:merge).with("production")

            Zenflow::Version.should_receive(:update).with(:patch)

            Zenflow::Changelog.should_receive(:update).with(rotate: true, name: "new-test-branch").and_return("YES")

            Zenflow::Branch.should_receive(:checkout).with("master")
            Zenflow::Branch.should_receive(:merge).with("test/new-test-branch")
            Zenflow::Branch.should_receive(:push).with("master")
            Zenflow::Branch.should_receive(:checkout).with("production")
            Zenflow::Branch.should_receive(:merge).with("test/new-test-branch")
            Zenflow::Branch.should_receive(:push).with("production")

            Zenflow::Branch.should_receive(:tag).with(Zenflow::Version.current.to_s, "YES")
            Zenflow::Branch.should_receive(:push).with(:tags)

            Zenflow::Branch.should_receive(:delete_remote).with("test/new-test-branch")
            Zenflow::Branch.should_receive(:delete_local).with("test/new-test-branch", force: true)
          end
          it { TestCommand.new.invoke(:finish) }
        end

        context "when offline" do
          before do
            Zenflow::Branch.should_receive(:checkout).with("test/new-test-branch")
            Zenflow::Branch.should_receive(:merge).with("production")

            Zenflow::Version.should_receive(:update).with(:patch)

            Zenflow::Changelog.should_receive(:update).with(rotate: true, name: "new-test-branch").and_return("YES")

            Zenflow::Branch.should_receive(:checkout).with("master")
            Zenflow::Branch.should_receive(:merge).with("test/new-test-branch")
            Zenflow::Branch.should_receive(:checkout).with("production")
            Zenflow::Branch.should_receive(:merge).with("test/new-test-branch")

            Zenflow::Branch.should_receive(:tag).with(Zenflow::Version.current.to_s, "YES")

            Zenflow::Branch.should_receive(:delete_local).with("test/new-test-branch", force: true)
          end
          it { TestCommand.new.invoke(:finish, [], offline: true) }
        end
      end
    end

  end
end
