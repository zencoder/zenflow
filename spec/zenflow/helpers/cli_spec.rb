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

  describe "#configure_staging_branch" do
    let(:question) {["Use a branch for staging releases and hotfixes?", {:options => ["Y", "n"], :default => "Y"}]}

    context "when the user wants to configure a staging branch" do
      before do
        Zenflow.should_receive(:Ask).with(*question).and_return('y')
      end

      it 'names the staging branch whatever the user wants' do
        Zenflow.should_receive(:Ask).with("What is the name of that branch?", :default => "staging").and_return('staging')
        Zenflow::Config.should_receive(:[]=).with(:staging_branch, 'staging')
        subject.configure_staging_branch
      end
    end

    context "when the user does not want to configure a staging branch" do
      before do
        Zenflow.should_receive(:Ask).with(*question).and_return('n')
      end

      it 'names the staging branch whatever the user wants' do
        Zenflow::Config.should_receive(:[]=).with(:staging_branch, false)
        subject.configure_staging_branch
      end
    end
  end

  describe "#configure_qa_branch" do
    let(:question) {["Use a branch for testing features?", {:options => ["Y", "n"], :default => "Y"}]}

    context "when the user wants to configure a qa branch" do
      before do
        Zenflow.should_receive(:Ask).with(*question).and_return('y')
      end

      it 'names the staging branch whatever the user wants' do
        Zenflow.should_receive(:Ask).with("What is the name of that branch?", :default => "qa").and_return('qa')
        Zenflow::Config.should_receive(:[]=).with(:qa_branch, 'qa')
        subject.configure_qa_branch
      end
    end

    context "when the user does not want to configure a qa branch" do
      before do
        Zenflow.should_receive(:Ask).with(*question).and_return('n')
      end

      it 'names the staging branch whatever the user wants' do
        Zenflow::Config.should_receive(:[]=).with(:qa_branch, false)
        subject.configure_qa_branch
      end
    end
  end

  describe "#configure_release_branch" do
    let(:question) {["Use a release branch?", {:options=>["Y", "n"], :default=>"Y"}]}

    context "when the user wants to configure a release branch" do
      before do
        Zenflow.should_receive(:Ask).with(*question).and_return('y')
      end

      it 'names the staging branch whatever the user wants' do
        Zenflow.should_receive(:Ask).with("What is the name of the release branch?", :default => "production").and_return('production')
        Zenflow::Config.should_receive(:[]=).with(:release_branch, 'production')
        subject.configure_release_branch
      end
    end

    context "when the user does not want to configure a release branch" do
      before do
        Zenflow.should_receive(:Ask).with(*question).and_return('n')
      end

      it 'names the staging branch whatever the user wants' do
        Zenflow::Config.should_receive(:[]=).with(:release_branch, false)
        subject.configure_release_branch
      end
    end
  end

end
