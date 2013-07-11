require 'spec_helper'

module BranchCommandSpecs
  module Review

    class TestCommand < Zenflow::BranchCommands::Review
      flow "test"
      branch source: "master"
      branch destination: "production"
      branch deploy: "deploy1"
      branch deploy: "deploy2"
      version :patch
      changelog :rotate
      tag true
    end

    describe "Zenflow::BranchCommands::Review" do

      context "when pull request is found" do
        before do
          Zenflow::Branch.should_receive(:current).with("test").and_return("new-test-branch")
          Zenflow::PullRequest.should_receive(:find_by_ref).with("test/new-test-branch").and_return({ html_url: "URL"})
          Zenflow.should_receive(:Log).with("A pull request for test/new-test-branch already exists", color: :red)
          Zenflow.should_receive(:Log).with("URL", indent: true, color: false)
        end
        it { expect{TestCommand.new.invoke(:review)}.to raise_error(SystemExit) }
      end

      context "with new pull request" do
        before do
          Zenflow::Branch.should_receive(:current).with("test").and_return("new-test-branch")
          Zenflow::PullRequest.should_receive(:find_by_ref).with("test/new-test-branch").and_return(false)
        end

        context "with valid request" do
          before do
            Zenflow.should_receive(:Ask).with("Describe this test:", required: true).and_return("A great test")
            pull = double(valid?: true)
            pull.stub(:[]).with("html_url").and_return("URL")
            Zenflow::PullRequest.should_receive(:create).with(
              base:  "master",
              head:  "test/new-test-branch",
              title: "test: new-test-branch",
              body:  "A great test"
            ).and_return(pull)
            Zenflow.should_receive(:Log).with("Pull request was created!")
            Zenflow.should_receive(:Log).with("URL", indent: true, color: false)
            Zenflow::Shell.should_receive(:[]).with("open URL")
          end
          it { TestCommand.new.invoke(:review) }
        end

        context "with invalid request" do
          let(:pull){ double(valid?: false) }

          before do
            Zenflow.should_receive(:Ask).with("Describe this test:", required: true).and_return("A great test")
            Zenflow::PullRequest.should_receive(:create).with(
              base:  "master",
              head:  "test/new-test-branch",
              title: "test: new-test-branch",
              body:  "A great test"
            ).and_return(pull)
            Zenflow.should_receive(:Log).with("There was a problem creating the pull request:", color: :red)
          end

          it "displays errors" do
            pull.stub(:[]).with("errors").and_return([{"message" => "ERROR"},{"message" => "ERROR"}])
            Zenflow.should_receive(:Log).with("* ERROR", indent: true, color: :red).twice
            TestCommand.new.invoke(:review)
          end

          it "displays an error message" do
            pull.stub(:[]).with("errors")
            pull.stub(:[]).with("message").and_return("ERROR")
            Zenflow.should_receive(:Log).with("* ERROR", indent: true, color: :red)
            TestCommand.new.invoke(:review)
          end

          it "handles unexpected failure" do
            pull.stub(:[]).with("errors")
            pull.stub(:[]).with("message")
            Zenflow.should_receive(:Log).with(" * unexpected failure, both 'errors' and 'message' were empty in the response")
            TestCommand.new.invoke(:review)
          end
        end
      end

    end

  end
end
