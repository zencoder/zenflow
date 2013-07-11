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

  describe "#configure_project" do
    it 'asks the user to name their project' do
      Zenflow.should_receive(:Ask).with("What is the name of this project?", :required => true).and_return('zenflow')
      Zenflow.should_receive(:Log).with("Project")
      Zenflow::Config.should_receive(:[]=).with(:project, 'zenflow')
      subject.configure_project
    end
  end

  def configure_branches
    Zenflow::Log("Branches")
    Zenflow::Config[:development_branch] = Zenflow::Ask("What is the name of the main development branch?", :default => "master")
    configure_branch(:staging_branch, "Use a branch for staging releases and hotfixes?", "staging")
    configure_branch(:qa_branch, "Use a branch for testing features?", "qa")
    configure_branch(:release_branch, "Use a release branch?", "production")
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

end
