require 'spec_helper'

describe Zenflow::Github do
  describe '.user' do
    let(:user){'github-user'}

    before(:each){
      Zenflow::Shell.should_receive(:run).and_return(user)
    }

    it "returns the user" do
      expect(Zenflow::Github.user).to eq(user)
    end
  end

  describe '.set_user' do
    let(:user){'github-user'}

    it 'asks for the user name and sets it to github.user' do
      Zenflow.should_receive(:Ask).and_return(user)
      Zenflow::Shell.should_receive(:run).with(/github\.user #{user}/, :silent => true)
      Zenflow::Github.set_user
    end
  end

  describe '.authorize' do
    context "when authorization fails" do
      before do
        Zenflow.should_receive("Log").with("Authorizing with GitHub... Enter your GitHub password.")
        Zenflow::Github.should_receive(:user).and_return('adamkittelson')
        Zenflow::Shell.should_receive(:run).and_return('{"message": "failed to authorize, bummer"}')
      end

      it "logs that something went wrong" do
        Zenflow.should_receive("Log").with("Something went wrong. Error from GitHub was: failed to authorize, bummer")
        Zenflow::Github.authorize
      end
    end

    context "when authorization succeeds" do
      before do
        Zenflow.should_receive("Log").with("Authorizing with GitHub... Enter your GitHub password.")
        Zenflow::Github.should_receive(:user).and_return('adamkittelson')
        Zenflow::Shell.should_receive(:run).with(%{curl -u "adamkittelson" https://api.github.com/authorizations -d '{"scopes":["repo"], "note":"Zenflow"}' --silent}, :silent => true).and_return('{"token": "super secure token"}')
      end

      it "adds the token to git config and logs a happy message of success" do
        Zenflow::Shell.should_receive(:run).with("git config --global zenflow.token super secure token", :silent => true)
        Zenflow.should_receive("Log").with("Authorized!")
        Zenflow::Github.authorize
      end
    end

  end
end
