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

  def already_configured
    Zenflow::Log("Warning", :color => :red)
    if Zenflow::Ask("There is an existing config file. Overwrite it?", :options => ["y", "N"], :default => "N") == "y"
      init(true)
    else
      Zenflow::Log("Aborting...", :color => :red)
      exit(1)
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
end
