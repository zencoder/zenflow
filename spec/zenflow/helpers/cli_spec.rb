require 'spec_helper'

describe Zenflow::CLI do

  subject {Zenflow::CLI.new}

  describe "#version" do
    it 'outputs the version number' do
      subject.should_receive(:puts).with("Zenflow #{Zenflow::VERSION}")
      subject.version
    end
  end

  describe "#help" do
    it 'displays helpful information' do
      subject.should_receive(:version)
      $stdout.should_receive(:puts).at_least(:once)
      subject.help
    end
  end

  describe "#set_up_github" do
    context "when a github user is already saved" do
      before do
        Zenflow::Github.should_receive(:user).and_return('user')
      end

      context "and the user decides to set a new one" do
        before do
          Zenflow.should_receive(:Ask).and_return('n')
        end

        it "authorizes with Github" do
          Zenflow::Github.should_receive(:set_user)
          subject.set_up_github
        end
      end

      context "and the user decides not to set a new one" do
        before do
          Zenflow.should_receive(:Ask).and_return('y')
        end

        it "does not authorize with Github" do
          Zenflow::Github.should_not_receive(:set_user)
          subject.set_up_github
        end
      end
    end

    context "when a zenflow_token is not already saved" do
      before do
        Zenflow::Github.should_receive(:user).and_return(nil)
      end

      it "authorizes with Github" do
        Zenflow::Github.should_receive(:set_user)
        subject.set_up_github
      end
    end
  end

  describe "#authorize_github" do
    context "when a zenflow_token is already saved" do
      before do
        Zenflow::Github.should_receive(:zenflow_token).and_return('super secret token')
      end

      context "and the user decides to set a new one" do
        before do
          Zenflow.should_receive(:Ask).and_return('y')
        end

        it "authorizes with Github" do
          Zenflow::Github.should_receive(:authorize)
          subject.authorize_github
        end
      end

      context "and the user decides not to set a new one" do
        before do
          Zenflow.should_receive(:Ask).and_return('n')
        end

        it "does not authorize with Github" do
          Zenflow::Github.should_not_receive(:authorize)
          subject.authorize_github
        end
      end
    end

    context "when a zenflow_token is not already saved" do
      before do
        Zenflow::Github.should_receive(:zenflow_token).and_return(nil)
      end

      it "authorizes with Github" do
        Zenflow::Github.should_receive(:authorize)
        subject.authorize_github
      end
    end
  end

  describe "#already_configured" do
    let(:question) {['There is an existing config file. Overwrite it?', {:options => ["y", "N"], :default => "N"}]}
    before do
      Zenflow.should_receive(:Log).with('Warning', :color => :red)
    end

    context "when the user wants to overwrite the configuration" do
      before do
        Zenflow.should_receive(:Ask).with(*question).and_return('y')
      end

      it "forces initialization" do
        subject.should_receive(:init).with(true)
        subject.already_configured
      end
    end

    context "when the user does not want to overwrite the configuration" do
      before do
        Zenflow.should_receive(:Ask).with(*question).and_return('n')
      end

      it "aborts" do
        Zenflow.should_receive(:Log).with('Aborting...', :color => :red)
        lambda{ subject.already_configured}.should raise_error(SystemExit)
      end
    end
  end

  describe "#configure_branch" do
    context "when the user wants to configure a staging branch" do
      before do
        Zenflow.should_receive(:Ask).with("Use a branch for staging releases and hotfixes?", :options => ["Y", "n"], :default => "Y").and_return('y')
      end

      it 'names the staging branch whatever the user wants' do
        Zenflow.should_receive(:Ask).with("What is the name of that branch?", :default => "staging").and_return('staging')
        Zenflow::Config.should_receive(:[]=).with(:staging_branch, 'staging')
        subject.configure_branch(:staging_branch, "Use a branch for staging releases and hotfixes?", 'staging')
      end
    end

    context "when the user does not want to configure a staging branch" do
      before do
        Zenflow.should_receive(:Ask).with("Use a branch for staging releases and hotfixes?", :options => ["Y", "n"], :default => "Y").and_return('n')
      end

      it 'names the staging branch whatever the user wants' do
        Zenflow::Config.should_receive(:[]=).with(:staging_branch, false)
        subject.configure_branch(:staging_branch, "Use a branch for staging releases and hotfixes?", 'staging')
      end
    end
  end

  describe "#configure_merge_strategy" do
    context "when the user wants to keep the default merge strategy of 'merge'" do
      it 'sets the merge strategy to merge' do
        Zenflow.should_receive(:Ask).with("What merge strategy would you prefer?", :options => ["merge", "rebase"], :default => "merge").and_return('merge')
        Zenflow::Config.should_receive(:[]=).with(:merge_strategy, 'merge')
        subject.configure_merge_strategy
      end
    end

    context "when the user wants to change the default merge strategy to 'rebase'" do
      it 'sets the merge strategy to rebase' do
        Zenflow.should_receive(:Ask).with("What merge strategy would you prefer?", :options => ["merge", "rebase"], :default => "merge").and_return('rebase')
        Zenflow::Config.should_receive(:[]=).with(:merge_strategy, 'rebase')
        subject.configure_merge_strategy
      end
    end
  end

  describe "#configure_project" do
    it 'asks the user to name their project' do
      Zenflow.should_receive(:Ask).with("What is the name of this project?", :required => true).and_return('zenflow')
      Zenflow.should_receive(:Log).with("Project")
      Zenflow::Config.should_receive(:[]=).with(:project, 'zenflow')
      subject.configure_project
    end
  end

  describe "#configure_branches" do
    it 'configures branches for the project' do
      Zenflow.should_receive(:Ask).with("What is the name of the main development branch?", :default => "master").and_return('master')
      Zenflow.should_receive(:Log).with("Branches")
      Zenflow::Config.should_receive(:[]=).with(:development_branch, 'master')
      subject.should_receive(:configure_branch).exactly(3).times
      subject.configure_branches
    end
  end

  describe "#configure_remotes" do
    context "when the user wants to configure a backup remote" do
      before do
        Zenflow.should_receive(:Ask).with("Use a backup remote?", :options => ["Y", "n"], :default => "n").and_return('y')
      end

      it 'configures the primary remote and a backup remote' do
        Zenflow.should_receive(:Ask).with("What is the name of your primary remote?", :default => "origin").and_return('origin')
        Zenflow::Config.should_receive(:[]=).with(:remote, 'origin')
        Zenflow.should_receive(:Ask).with("What is the name of your backup remote?", :default => "backup").and_return('backup')
        Zenflow::Config.should_receive(:[]=).with(:backup_remote, 'backup')
        subject.configure_remotes
      end
    end

    context "when the user does not want to configure a backup remote" do
      before do
        Zenflow.should_receive(:Ask).with("Use a backup remote?", :options => ["Y", "n"], :default => "n").and_return('n')
      end

      it 'configures the primary remote and a backup remote' do
        Zenflow.should_receive(:Ask).with("What is the name of your primary remote?", :default => "origin").and_return('origin')
        Zenflow::Config.should_receive(:[]=).with(:remote, 'origin')
        Zenflow.should_not_receive(:Ask).with("What is the name of your backup remote?", :default => "backup")
        Zenflow::Config.should_receive(:[]=).with(:backup_remote, false)
        subject.configure_remotes
      end
    end
  end

  describe "#set_up_changelog" do
    context "when the changelog doesn't already exist" do
      before do
        File.should_receive(:exist?).with("CHANGELOG.md").and_return(false)
        Zenflow.should_receive(:Log).with("Changelog Management")
      end

      context "when the user wants to set up a changelog" do
        it 'sets up the changelog' do
          Zenflow.should_receive(:Ask).with("Set up a changelog?", :options => ["Y", "n"], :default => "Y").and_return('y')
          Zenflow::Changelog.should_receive(:create)
          subject.set_up_changelog
        end
      end

      context "when the user does not want to set up a changelog" do
        it 'does not set up the changelog' do
          Zenflow.should_receive(:Ask).with("Set up a changelog?", :options => ["Y", "n"], :default => "Y").and_return('n')
          Zenflow::Changelog.should_not_receive(:create)
          subject.set_up_changelog
        end
      end
    end

    context "when the changelog already exists" do
      before do
        File.should_receive(:exist?).with("CHANGELOG.md").and_return(true)
      end

      it 'does not set up the changelog' do
        Zenflow.should_not_receive(:Log).with("Changelog Management")
        Zenflow.should_not_receive(:Ask).with("Set up a changelog?", :options => ["Y", "n"], :default => "Y")
        Zenflow::Changelog.should_not_receive(:create)
        subject.set_up_changelog
      end
    end
  end

  describe "#confirm_some_stuff" do
    it "confirms staging deployment and code review requirements" do
      Zenflow.should_receive(:Log).with("Confirmations")
      Zenflow.should_receive(:Ask).with("Require deployment to a staging environment?", :options => ["Y", "n"], :default => "Y").and_return('y')
      Zenflow::Config.should_receive(:[]=).with(:confirm_staging, true)
      Zenflow.should_receive(:Ask).with("Require code reviews?", :options => ["Y", "n"], :default => "Y").and_return('n')
      Zenflow::Config.should_receive(:[]=).with(:confirm_review, false)
      subject.confirm_some_stuff
    end
  end

  describe "#init" do
    context "when zenflow has not been configured" do
      before do
        Zenflow::Config.should_receive(:configured?).and_return(false)
      end

      it 'configures zenflow' do
        subject.should_not_receive(:already_configured)
        subject.should_receive(:set_up_github)
        subject.should_receive(:authorize_github)
        subject.should_receive(:configure_project)
        subject.should_receive(:configure_branches)
        subject.should_receive(:configure_merge_strategy)
        subject.should_receive(:configure_remotes)
        subject.should_receive(:confirm_some_stuff)
        subject.should_receive(:set_up_changelog)
        Zenflow::Config.should_receive(:save!)
        subject.init
      end
    end

    context "when zenflow has already been configured" do
      before do
        Zenflow::Config.should_receive(:configured?).and_return(true)
      end

      context 'and it is forced to initialize' do
        it 'configures zenflow' do
          subject.should_not_receive(:already_configured)
          subject.should_receive(:set_up_github)
          subject.should_receive(:authorize_github)
          subject.should_receive(:configure_project)
          subject.should_receive(:configure_branches)
          subject.should_receive(:configure_merge_strategy)
          subject.should_receive(:configure_remotes)
          subject.should_receive(:confirm_some_stuff)
          subject.should_receive(:set_up_changelog)
          Zenflow::Config.should_receive(:save!)
          subject.init(true)
        end
      end

      context 'and it is forced to initialize' do
        before do
          Zenflow.should_receive(:Log).with('Warning', :color => :red)
          Zenflow.should_receive(:Ask).and_return('n')
          Zenflow.should_receive(:Log).with('Aborting...', :color => :red)
        end

        it 'calls already_configured' do
          subject.should_receive(:already_configured).and_call_original
          subject.should_not_receive(:authorize_github)
          subject.should_not_receive(:configure_project)
          subject.should_not_receive(:configure_branches)
          subject.should_not_receive(:configure_merge_strategy)
          subject.should_not_receive(:configure_remotes)
          subject.should_not_receive(:confirm_some_stuff)
          subject.should_not_receive(:set_up_changelog)
          Zenflow::Config.should_not_receive(:save!)
          lambda{ subject.init}.should raise_error(SystemExit)
        end
      end
    end
  end

end
