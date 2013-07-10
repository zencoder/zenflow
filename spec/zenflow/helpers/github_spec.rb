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

  describe '.token' do
    let(:token) {'github-token-for-you'}

    before(:each) {
      Zenflow::Shell.should_receive(:run).and_return(token)
    }

    it "returns the token" do
      expect(Zenflow::Github.token).to eq(token)
    end
  end

  describe '.zenflow_token' do
    let!(:token){'zenflow-token-for-you'}

    before do
      Zenflow::Shell.should_receive(:run).and_return(token)
    end

    it "sets the zenflow token" do
      expect(Zenflow::Github.zenflow_token).to eq(token)
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
