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
        expect(Zenflow).to receive(:Log).with("Available test branches:")
        expect(Zenflow::Branch).to receive(:list).with("test").and_return(["YES"])
        expect(Zenflow).to receive(:Log).with("* YES", indent: true, color: false)
      end
      it { TestCommand.new.invoke(:branches) }
    end

    describe "#start" do
      context "when online" do
        context 'merge_strategy: merge' do
          before do
            expect(Zenflow).to receive(:Ask).and_return("new-test-branch")
            expect(Zenflow::Branch).to receive(:update).with("master")
            expect(Zenflow::Branch).to receive(:create).with("test/new-test-branch", "master")
            expect(Zenflow::Branch).to receive(:push).with("test/new-test-branch")
            expect(Zenflow::Branch).to receive(:track).with("test/new-test-branch")
          end
          it { TestCommand.new.invoke(:start) }
        end

        context 'merge_strategy: rebase' do
          before do
            expect(Zenflow::Config).to receive(:[]).with(:merge_strategy).and_return('rebase')
            expect(Zenflow).to receive(:Ask).and_return("new-test-branch")
            expect(Zenflow::Branch).to receive(:update).with("master")
            expect(Zenflow::Branch).to receive(:create).with("test/new-test-branch", "master")
            expect(Zenflow::Branch).to_not receive(:push).with("test/new-test-branch")
            expect(Zenflow::Branch).to_not receive(:track).with("test/new-test-branch")
          end
          it { TestCommand.new.invoke(:start) }
        end
      end

      context "when offline" do
        before do
          expect(Zenflow).to receive(:Ask).and_return("new-test-branch")
          expect(Zenflow::Branch).to receive(:checkout).with("master")
          expect(Zenflow::Branch).to receive(:create).with("test/new-test-branch", "master")
        end
        it { TestCommand.new.invoke(:start, nil, offline: true) }
      end

      context "when supplying a name" do
        before do
          expect(Zenflow::Branch).to receive(:update).with("master")
          expect(Zenflow::Branch).to receive(:create).with("test/new-test-branch", "master")
          expect(Zenflow::Branch).to receive(:push).with("test/new-test-branch")
          expect(Zenflow::Branch).to receive(:track).with("test/new-test-branch")
        end
        it { TestCommand.new.invoke(:start, ["new-test-branch"]) }
      end

      context "when asking for a name" do
        before do
          expect($stdin).to receive(:gets).and_return("new-test-branch\n")
          expect(Zenflow::Branch).to receive(:update).with("master")
          expect(Zenflow::Branch).to receive(:create).with("test/new-test-branch", "master")
          expect(Zenflow::Branch).to receive(:push).with("test/new-test-branch")
          expect(Zenflow::Branch).to receive(:track).with("test/new-test-branch")
        end
        it { expect(capture(:stdout){ TestCommand.new.invoke(:start) }).to eq(">> Name of the test: ") }
      end
    end

    describe "#deploy" do
      context "when a project is not deployable" do
        before do
          expect(Zenflow::Branch).to receive(:current).with("test").and_return("new-test-branch")
          expect(Zenflow::Config).to receive(:[]).with(:deployable).and_return(false)
          expect(Zenflow).to receive(:Log).with("This project is not deployable right now", color: :red)
        end
        it { expect{TestCommand.new.invoke(:deploy)}.to raise_error(SystemExit) }
      end

      context "without running migrations" do
        before do
          expect(Zenflow::Branch).to receive(:current).with("test").and_return("new-test-branch")
          expect(Zenflow::Config).to receive(:[]).with(:deployable).and_return(true)
          expect(Zenflow::Branch).to receive(:update).with("deploy1")
          expect(Zenflow::Branch).to receive(:update).with("deploy2")
          expect(Zenflow::Branch).to receive(:merge).with("test/new-test-branch").twice
          expect(Zenflow).to receive(:Deploy).with("deploy1", {})
          expect(Zenflow).to receive(:Deploy).with("deploy2", {})
          expect(Zenflow::Branch).to receive(:checkout).with("test/new-test-branch")
        end
        it { TestCommand.new.invoke(:deploy) }
      end

      context "when running migrations" do
        before do
          expect(Zenflow::Branch).to receive(:current).with("test").and_return("new-test-branch")
          expect(Zenflow::Config).to receive(:[]).with(:deployable).and_return(true)
          expect(Zenflow::Branch).to receive(:update).with("deploy1")
          expect(Zenflow::Branch).to receive(:update).with("deploy2")
          expect(Zenflow::Branch).to receive(:merge).with("test/new-test-branch").twice
          expect(Zenflow).to receive(:Deploy).with("deploy1", { "migrations" => true })
          expect(Zenflow).to receive(:Deploy).with("deploy2", { "migrations" => true })
          expect(Zenflow::Branch).to receive(:checkout).with("test/new-test-branch")
        end
        it { TestCommand.new.invoke(:deploy, [], "migrations" => true) }
      end
    end

    describe "#update" do
      context "merge_strategy: merge" do
        before do
          expect(Zenflow::Config).to receive(:[]).with(:merge_strategy).and_return('merge')
          expect(Zenflow::Branch).to receive(:current).with("test").and_return("new-test-branch")
          expect(Zenflow::Branch).to receive(:checkout).with("test/new-test-branch")
          expect(Zenflow::Branch).to receive(:merge).with("master")

          context "no override for --rebase" do
            expect(Zenflow::Branch).to receive(:update).with("master", nil)
            it { TestCommand.new.invoke(:update) }
          end

          context "override for --rebase" do
            expect(Zenflow::Branch).to receive(:update).with("master", true)
            it { TestCommand.new.invoke(:update, true) }
          end
        end
      end

      context "merge_strategy: rebase" do
        before do
          expect(Zenflow::Config).to receive(:[]).with(:merge_strategy).and_return('rebase')
          expect(Zenflow::Branch).to receive(:current).with("test").and_return("new-test-branch")
          expect(Zenflow::Branch).to receive(:update).with("master", nil)
          expect(Zenflow::Branch).to receive(:rebase).with("test/new-test-branch", 'master')
        end
        it { TestCommand.new.invoke(:update) }
      end
    end

    describe "#diff" do
      before do
        expect(Zenflow).to receive(:Log).with("Displaying diff with master")
        expect(Zenflow::Shell).to receive(:[]).with("git difftool master")
      end
      it { TestCommand.new.invoke(:diff) }
    end

    describe "#compare" do
      before do
        expect(Zenflow::Branch).to receive(:current).with("test").and_return("new-test-branch")
        expect(Zenflow).to receive(:Log).with("Opening GitHub compare view for master...test/new-test-branch")
        expect(Zenflow::Repo).to receive(:slug).and_return("test-repo")
        expect(Zenflow::Shell).to receive(:[]).with("open https://github.com/test-repo/compare/master...test/new-test-branch")
      end
      it { TestCommand.new.invoke(:compare) }
    end

    describe "#review" do
      context "when pull request is found" do
        before do
          expect(Zenflow::Branch).to receive(:current).with("test").and_return("new-test-branch")
          expect(Zenflow::PullRequest).to receive(:find_by_ref).with("test/new-test-branch").and_return({ html_url: "URL"})
          expect(Zenflow).to receive(:Log).with("A pull request for test/new-test-branch already exists", color: :red)
          expect(Zenflow).to receive(:Log).with("URL", indent: true, color: false)
        end
        it { expect{TestCommand.new.invoke(:review)}.to raise_error(SystemExit) }
      end

      context "with new pull request" do
        before do
          expect(Zenflow::Branch).to receive(:current).with("test").and_return("new-test-branch")
          expect(Zenflow::PullRequest).to receive(:find_by_ref).with("test/new-test-branch").and_return(false)
        end

        context "with valid request" do
          before do
            expect(Zenflow).to receive(:Ask).with("Describe this test:", required: true).and_return("A great test")
            pull = double(valid?: true)
            allow(pull).to receive(:[]).with("html_url").and_return("URL")
            expect(Zenflow::PullRequest).to receive(:create).with(
              base:  "production",
              head:  "test/new-test-branch",
              title: "test: new-test-branch",
              body:  "A great test"
            ).and_return(pull)
            expect(Zenflow).to receive(:Log).with("Pull request was created!")
            expect(Zenflow).to receive(:Log).with("URL", indent: true, color: false)
            expect(Zenflow::Shell).to receive(:[]).with("open URL")
          end
          it { TestCommand.new.invoke(:review) }
        end

        context "with invalid request" do
          let(:pull){ double(valid?: false) }

          before do
            expect(Zenflow).to receive(:Ask).with("Describe this test:", required: true).and_return("A great test")
            expect(Zenflow::PullRequest).to receive(:create).with(
              base:  "production",
              head:  "test/new-test-branch",
              title: "test: new-test-branch",
              body:  "A great test"
            ).and_return(pull)
            expect(Zenflow).to receive(:Log).with("There was a problem creating the pull request:", color: :red)
          end

          it "displays errors" do
            allow(pull).to receive(:[]).with("errors").and_return([{"message" => "ERROR"},{"message" => "ERROR"}])
            expect(Zenflow).to receive(:Log).with("* ERROR", indent: true, color: :red).twice
            TestCommand.new.invoke(:review)
          end

          it "displays an error message" do
            allow(pull).to receive(:[]).with("errors")
            allow(pull).to receive(:[]).with("message").and_return("ERROR")
            expect(Zenflow).to receive(:Log).with("* ERROR", indent: true, color: :red)
            TestCommand.new.invoke(:review)
          end

          it "handles unexpected failure" do
            allow(pull).to receive(:[]).with("errors")
            allow(pull).to receive(:[]).with("message")
            expect(Zenflow).to receive(:Log).with(" * unexpected failure, both 'errors' and 'message' were empty in the response")
            TestCommand.new.invoke(:review)
          end
        end
      end
    end

    describe "#abort" do
      let(:branch_name){"test/new-test-branch"}
      before {
        expect(Zenflow::Branch).to receive(:current).with("test").and_return("new-test-branch")
        expect(Zenflow::Branch).to receive(:checkout).with("master")
      }

      context "when online" do
        before do
          expect(Zenflow::Branch).to receive(:delete_remote).with(branch_name)
          expect(Zenflow::Branch).to receive(:delete_local).with(branch_name, force: true)
        end
        it { TestCommand.new.invoke(:abort) }
      end

      context "when offline" do
        before do
          expect(Zenflow::Branch).to receive(:delete_local).with(branch_name, force: true)
        end
        it { TestCommand.new.invoke(:abort, [], offline: true) }
      end
    end

    describe "#finish" do
      before do
        expect(Zenflow::Branch).to receive(:current).with("test").and_return("new-test-branch")
      end

      context "with confirmations" do
        it "without deployment to staging" do
          expect(Zenflow::Config).to receive(:[]).with(:confirm_staging).and_return(true)
          expect(Zenflow).to receive(:Ask).with("Has this been tested in a staging environment first?", options: ["Y", "n"], default: "y").and_return("n")
          expect(Zenflow).to receive(:Log).with("Sorry, deploy to a staging environment first", color: :red)
          expect{TestCommand.new.invoke(:finish)}.to raise_error(SystemExit)
        end

        it "without review" do
          expect(Zenflow::Config).to receive(:[]).with(:confirm_staging).and_return(true)
          expect(Zenflow::Config).to receive(:[]).with(:confirm_review).and_return(true)
          expect(Zenflow).to receive(:Ask).with("Has this been tested in a staging environment first?", options: ["Y", "n"], default: "y").and_return("y")
          expect(Zenflow).to receive(:Ask).with("Has this been code reviewed yet?", options: ["Y", "n"], default: "y").and_return("n")
          expect(Zenflow).to receive(:Log).with("Please have someone look at this first", color: :red)
          expect{TestCommand.new.invoke(:finish)}.to raise_error(SystemExit)
        end
      end

      context "without confirmations" do
        before do
          expect(Zenflow::Config).to receive(:[]).with(:confirm_staging).and_return(false)
          expect(Zenflow::Config).to receive(:[]).with(:confirm_review).and_return(false)
        end

        context "with a merge_strategy of 'merge'" do
          before do
            expect(Zenflow::Config).to receive(:[]).with(:merge_strategy).and_return('merge')
          end

          context "when online" do
            before do
              expect(Zenflow::Branch).to receive(:update).with("production")
              expect(Zenflow::Branch).to receive(:checkout).with("test/new-test-branch")
              expect(Zenflow::Branch).to receive(:merge).with("production")

              expect(Zenflow::Version).to receive(:update).with(:patch)

              expect(Zenflow::Changelog).to receive(:update).with(rotate: true, name: "new-test-branch").and_return("YES")

              expect(Zenflow::Branch).to receive(:checkout).with("master")
              expect(Zenflow::Branch).to receive(:merge).with("test/new-test-branch")
              expect(Zenflow::Branch).to receive(:push).with("master")
              expect(Zenflow::Branch).to receive(:checkout).with("production")
              expect(Zenflow::Branch).to receive(:merge).with("test/new-test-branch")
              expect(Zenflow::Branch).to receive(:push).with("production")

              expect(Zenflow::Branch).to receive(:tag).with(Zenflow::Version.current.to_s, "YES")
              expect(Zenflow::Branch).to receive(:push_tags)

              expect(Zenflow::Branch).to receive(:delete_remote).with("test/new-test-branch")
              expect(Zenflow::Branch).to receive(:delete_local).with("test/new-test-branch", force: true)
            end
            it { TestCommand.new.invoke(:finish) }
          end

          context "when offline" do
            before do
              expect(Zenflow::Branch).to receive(:checkout).with("test/new-test-branch")
              expect(Zenflow::Branch).to receive(:merge).with("production")

              expect(Zenflow::Version).to receive(:update).with(:patch)

              expect(Zenflow::Changelog).to receive(:update).with(rotate: true, name: "new-test-branch").and_return("YES")

              expect(Zenflow::Branch).to receive(:checkout).with("master")
              expect(Zenflow::Branch).to receive(:merge).with("test/new-test-branch")
              expect(Zenflow::Branch).to receive(:checkout).with("production")
              expect(Zenflow::Branch).to receive(:merge).with("test/new-test-branch")

              expect(Zenflow::Branch).to receive(:tag).with(Zenflow::Version.current.to_s, "YES")

              expect(Zenflow::Branch).to receive(:delete_local).with("test/new-test-branch", force: true)
            end
            it { TestCommand.new.invoke(:finish, [], offline: true) }
          end
        end

        context "with a merge_strategy of 'rebase'" do
          before do
            expect(Zenflow::Config).to receive(:[]).with(:merge_strategy).and_return('rebase')
          end

          context "when online" do
            before do
              expect(Zenflow::Branch).to receive(:update).with("production")
              expect(Zenflow::Branch).to receive(:rebase).with("test/new-test-branch", 'production')

              expect(Zenflow::Version).to receive(:update).with(:patch)

              expect(Zenflow::Changelog).to receive(:update).with(rotate: true, name: "new-test-branch").and_return("YES")

              expect(Zenflow::Branch).to receive(:checkout).with("master")
              expect(Zenflow::Branch).to receive(:merge).with("test/new-test-branch")
              expect(Zenflow::Branch).to receive(:push).with("master")
              expect(Zenflow::Branch).to receive(:checkout).with("production")
              expect(Zenflow::Branch).to receive(:merge).with("test/new-test-branch")
              expect(Zenflow::Branch).to receive(:push).with("production")

              expect(Zenflow::Branch).to receive(:tag).with(Zenflow::Version.current.to_s, "YES")
              expect(Zenflow::Branch).to receive(:push_tags)

              expect(Zenflow::Branch).to receive(:delete_remote).with("test/new-test-branch")
              expect(Zenflow::Branch).to receive(:delete_local).with("test/new-test-branch", force: true)
            end
            it { TestCommand.new.invoke(:finish) }
          end

          context "when offline" do
            before do
              expect(Zenflow::Branch).to receive(:rebase).with("test/new-test-branch", 'production')

              expect(Zenflow::Version).to receive(:update).with(:patch)

              expect(Zenflow::Changelog).to receive(:update).with(rotate: true, name: "new-test-branch").and_return("YES")

              expect(Zenflow::Branch).to receive(:checkout).with("master")
              expect(Zenflow::Branch).to receive(:merge).with("test/new-test-branch")
              expect(Zenflow::Branch).to receive(:checkout).with("production")
              expect(Zenflow::Branch).to receive(:merge).with("test/new-test-branch")

              expect(Zenflow::Branch).to receive(:tag).with(Zenflow::Version.current.to_s, "YES")

              expect(Zenflow::Branch).to receive(:delete_local).with("test/new-test-branch", force: true)
            end
            it { TestCommand.new.invoke(:finish, [], offline: true) }
          end
        end
      end
    end

    describe "#publish" do
      before do
        expect(Zenflow::Branch).to receive(:current).with("test").and_return("new-test-branch")
        expect(Zenflow::Branch).to receive(:push).with("test/new-test-branch")
        expect(Zenflow::Branch).to receive(:track).with("test/new-test-branch")
      end
      it { TestCommand.new.invoke(:publish) }
    end
  end

end
