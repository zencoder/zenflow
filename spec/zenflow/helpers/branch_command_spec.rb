require 'spec_helper'

module BranchCommandSpec

  class TestCommand < Zenflow::BranchCommand
    flow "test"
    branch source: "master"
    branch destination: "production"
    branch deploy: "deploy1"
    branch deploy: "deploy2"
    version :patch
    changelog :rotate
    tag true
  end

  describe "Zenflow::BranchCommand" do
    describe "#branches" do
      before do
        Zenflow.should_receive(:Log).with("Available test branches:")
        Zenflow::Branch.should_receive(:list).with("test").and_return(["YES"])
        Zenflow.should_receive(:Log).with("* YES", indent: true, color: false)
      end
      it { TestCommand.new.invoke(:branches) }
    end

    describe "#start" do
      context "when online" do
        before do
          Zenflow.should_receive(:Ask).and_return("new-test-branch")
          Zenflow::Branch.should_receive(:update).with("master")
          Zenflow::Branch.should_receive(:create).with("test/new-test-branch", "master")
          Zenflow::Branch.should_receive(:push).with("test/new-test-branch")
          Zenflow::Branch.should_receive(:track).with("test/new-test-branch")
        end
        it { TestCommand.new.invoke(:start) }
      end

      context "when offline" do
        before do
          Zenflow.should_receive(:Ask).and_return("new-test-branch")
          Zenflow::Branch.should_receive(:checkout).with("master")
          Zenflow::Branch.should_receive(:create).with("test/new-test-branch", "master")
        end
        it { TestCommand.new.invoke(:start, nil, offline: true) }
      end

      context "when supplying a name" do
        before do
          Zenflow::Branch.should_receive(:update).with("master")
          Zenflow::Branch.should_receive(:create).with("test/new-test-branch", "master")
          Zenflow::Branch.should_receive(:push).with("test/new-test-branch")
          Zenflow::Branch.should_receive(:track).with("test/new-test-branch")
        end
        it { TestCommand.new.invoke(:start, ["new-test-branch"]) }
      end

      context "when asking for a name" do
        before do
          $stdin.should_receive(:gets).and_return("new-test-branch\n")
          Zenflow::Branch.should_receive(:update).with("master")
          Zenflow::Branch.should_receive(:create).with("test/new-test-branch", "master")
          Zenflow::Branch.should_receive(:push).with("test/new-test-branch")
          Zenflow::Branch.should_receive(:track).with("test/new-test-branch")
        end
        it { expect(capture(:stdout){ TestCommand.new.invoke(:start) }).to eq(">> Name of the test: ") }
      end
    end

    describe "#deploy" do
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

    describe "#update" do
      context "merge_strategy: merge" do
        before do
          Zenflow::Config.should_receive(:[]).with(:merge_strategy).and_return('merge')
          Zenflow::Branch.should_receive(:current).with("test").and_return("new-test-branch")
          Zenflow::Branch.should_receive(:checkout).with("test/new-test-branch")
          Zenflow::Branch.should_receive(:merge).with("master")

          context "no override for --rebase" do
            Zenflow::Branch.should_receive(:update).with("master", nil)
            it { TestCommand.new.invoke(:update) }
          end

          context "override for --rebase" do
            Zenflow::Branch.should_receive(:update).with("master", true)
            it { TestCommand.new.invoke(:update, true) }
          end
        end
      end

      context "merge_strategy: rebase" do
        before do
          Zenflow::Config.should_receive(:[]).with(:merge_strategy).and_return('rebase')
          Zenflow::Branch.should_receive(:current).with("test").and_return("new-test-branch")
          Zenflow::Branch.should_receive(:update).with("master", nil)
          Zenflow::Branch.should_receive(:rebase).with("test/new-test-branch", 'master')
        end
        it { TestCommand.new.invoke(:update) }
      end
    end

    describe "#diff" do
      before do
        Zenflow.should_receive(:Log).with("Displaying diff with master")
        Zenflow::Shell.should_receive(:[]).with("git difftool master")
      end
      it { TestCommand.new.invoke(:diff) }
    end

    describe "#compare" do
      before do
        Zenflow::Branch.should_receive(:current).with("test").and_return("new-test-branch")
        Zenflow.should_receive(:Log).with("Opening GitHub compare view for master...test/new-test-branch")
        Zenflow::Repo.should_receive(:slug).and_return("test-repo")
        Zenflow::Shell.should_receive(:[]).with("open https://github.com/test-repo/compare/master...test/new-test-branch")
      end
      it { TestCommand.new.invoke(:compare) }
    end

    describe "#review" do
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

    describe "#abort" do
      let(:branch_name){"test/new-test-branch"}
      before {
        Zenflow::Branch.should_receive(:current).with("test").and_return("new-test-branch")
        Zenflow::Branch.should_receive(:checkout).with("master")
      }

      context "when online" do
        before do
          Zenflow::Branch.should_receive(:delete_remote).with(branch_name)
          Zenflow::Branch.should_receive(:delete_local).with(branch_name, force: true)
        end
        it { TestCommand.new.invoke(:abort) }
      end

      context "when offline" do
        before do
          Zenflow::Branch.should_receive(:delete_local).with(branch_name, force: true)
        end
        it { TestCommand.new.invoke(:abort, [], offline: true) }
      end
    end

    describe "#finish" do
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

        context "with a merge_strategy of 'merge'" do
          before do
            Zenflow::Config.should_receive(:[]).with(:merge_strategy).and_return('merge')
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

        context "with a merge_strategy of 'rebase'" do
          before do
            Zenflow::Config.should_receive(:[]).with(:merge_strategy).and_return('rebase')
          end

          context "when online" do
            before do
              Zenflow::Branch.should_receive(:update).with("production")
              Zenflow::Branch.should_receive(:rebase).with("test/new-test-branch", 'production')

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
              Zenflow::Branch.should_receive(:rebase).with("test/new-test-branch", 'production')

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

end
