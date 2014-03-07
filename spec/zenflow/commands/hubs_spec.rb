require 'spec_helper'

describe Zenflow::Hubs do
  let(:hubs) { Zenflow::Hubs.new }

  describe '.list' do
    it 'lists recognized hubs in git config' do
      Zenflow::Shell.should_receive(:run).with("git config --get-regexp zenflow\.hub\..*", silent: true).and_return(
<<EOS
zenflow.hub.hub.1.api.base.url api_base_url
zenflow.hub.yet.another.hub.github.user github_user
zenflow.hub.hub.1.token token
zenflow.hub.my-hub.token token
zenflow.hub.one.more.hub.user.agent.base user_agent_base
zenflow.hub.bad.token.hub.goobers user_agent_base
EOS
      )
      Zenflow::Repo.should_receive(:is_default_hub?).at_least(:once).with(anything()).and_return(false)
      Zenflow::Repo.should_receive(:is_current_hub?).at_least(:once).with(anything()).and_return(false)
      Zenflow.should_receive(:Log).with("Recogized hubs")
      Terminal::Table.should_receive(:new).with(
        headings: ["Hub"],
        rows: [
          ["github.com"],
          ["hub.1"],
          ["my-hub"],
          ["one.more.hub"],
          ["yet.another.hub"]
        ]
      ).and_return("log-data")
      Zenflow.should_receive(:Log).with("log-data", indent: false, arrows: false, color: false)
      hubs.list
    end
  end

  describe '.current' do
    it 'logs the hubs of the current project' do
      Zenflow::Repo.should_receive(:hub).twice.and_return('my-hub')
      Zenflow.should_receive(:Log).with("This project's hub is my-hub [current]")
      hubs.current
    end
  end

  describe '.describe' do
    it 'displays config parameters for the hub' do
      hubs.should_receive(:hub_label).with('my-hub').and_return('my-hub')
      Zenflow.should_receive(:Log).with("Configuration details for hub my-hub")
      Zenflow::Github.should_receive(:describe_hub).with('my-hub').and_return([
        ["Parameter 1", "Github Config Key 1", "Github Conifg Value 1", "Value 1"],
        ["Parameter 2", "Github Config Key 2", "Github Conifg Value 2", "Value 2"],
        ["Parameter 3", "Github Config Key 3", "Github Conifg Value 3", "Value 3"]
      ])
      Terminal::Table.should_receive(:new).with(
        headings: ["Parameter", "Github Config Key", "Github Config Value", "Value (with system defaults)"],
        rows: [
          ["Parameter 1", "Github Config Key 1", "Github Conifg Value 1", "Value 1"],
          ["Parameter 2", "Github Config Key 2", "Github Conifg Value 2", "Value 2"],
          ["Parameter 3", "Github Config Key 3", "Github Conifg Value 3", "Value 3"]
        ]
      ).and_return("log-data")
      Zenflow.should_receive(:Log).with("log-data", {:indent=>false, :arrows=>false, :color=>false})
      hubs.describe('my-hub')
    end
  end

  describe '.config' do
    it 'calls the individual parameter config methods' do
      Zenflow::Github.should_receive(:resolve_hub).with('my-hub').and_return('my-hub')
      hubs.should_receive(:hub_label).with('my-hub').and_return('my-hub')
      Zenflow.should_receive(:Log).with("Configuring my-hub")
      hubs.should_receive(:config_api_base_url).with('my-hub')
      hubs.should_receive(:config_user).with('my-hub')
      hubs.should_receive(:config_user_agent_base).with('my-hub')
      hubs.config('my-hub')
    end
  end

  describe '.config_user' do
    context 'when a github user is already saved' do
      before do
        Zenflow::Github.should_receive(:user).and_return('user')
      end

      context 'and the user decides to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('n')
        end

        it 'asks for a user' do
          Zenflow::Github.should_receive(:set_user)
          hubs.config_user('my-hub')
        end
      end

      context 'and the user decides not to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('y')
        end

        it 'does not ask for a user' do
          Zenflow::Github.should_not_receive(:set_user)
          hubs.config_user('my-hub')
        end
      end
    end

    context 'when a user is not already saved' do
      before do
        Zenflow::Github.should_receive(:user).and_return(nil)
      end

      it 'asks for a user' do
        Zenflow::Github.should_receive(:set_user)
        hubs.config_user('my-hub')
      end
    end
  end

  describe '.authorize' do
    before do
      Zenflow::Github.should_receive(:resolve_hub).with('my-hub').and_return('my-hub')
      hubs.should_receive(:hub_label).with('my-hub').and_return('my-hub')
      Zenflow.should_receive(:Log).with("Authorizing my-hub")
    end

    context 'when a zenflow_token is already saved' do
      before do
        Zenflow::Github.should_receive(:zenflow_token).and_return('super secret token')
      end

      context 'and the user decides to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('y')
        end

        it 'authorizes with Github' do
          Zenflow::Github.should_receive(:authorize).with('my-hub')
          hubs.authorize('my-hub')
        end
      end

      context 'and the user decides not to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('n')
        end

        it 'does not authorize with Github' do
          Zenflow::Github.should_not_receive(:authorize)
          hubs.authorize('my-hub')
        end
      end
    end

    context 'when a zenflow_token is not already saved' do
      before do
        Zenflow::Github.should_receive(:zenflow_token).and_return(nil)
      end

      it 'authorizes with Github' do
        Zenflow::Github.should_receive(:authorize).with('my-hub')
        hubs.authorize('my-hub')
      end
    end
  end

  describe '.hub_label' do
    context 'hub is default hub' do
      context 'hub is current hub' do
        before(:each){
          Zenflow::Repo.should_receive(:hub).and_return(Zenflow::Github::DEFAULT_HUB)
        }

        it 'returns the expected label' do
          expect(hubs.hub_label(Zenflow::Github::DEFAULT_HUB)).to eq("#{Zenflow::Github::DEFAULT_HUB} [default] [current]")
        end
      end

      context 'hub is not current hub' do
        before(:each){
          Zenflow::Repo.should_receive(:hub).and_return('current-hub')
        }

        it 'returns the expected label' do
          expect(hubs.hub_label(Zenflow::Github::DEFAULT_HUB)).to eq("#{Zenflow::Github::DEFAULT_HUB} [default]")
        end
      end
    end

    context 'hub is not default hub' do
      context 'hub is current hub' do
        before(:each){
          Zenflow::Repo.should_receive(:hub).and_return('current-hub')
        }

        it 'returns the expected label' do
          expect(hubs.hub_label('current-hub')).to eq('current-hub [current]')
        end
      end

      context 'hub is not current hub' do
        before(:each){
          Zenflow::Repo.should_receive(:hub).and_return('default-hub')
        }

        it 'returns the expected label' do
          expect(hubs.hub_label('not-current-hub')).to eq('not-current-hub')
        end
      end
    end
  end

  describe '.default_hub_tag' do
    context 'hub is default hub' do
      it 'returns the expected tag' do
        expect(hubs.default_hub_tag(Zenflow::Github::DEFAULT_HUB)).to eq(' [default]')
      end
    end

    context 'hub is not default hub' do
      it 'returns the expected tag' do
        expect(hubs.default_hub_tag('not-default-hub')).to eq('')
      end
    end
  end

  describe '.current_hub_tag' do
    before(:each){
      Zenflow::Repo.should_receive(:hub).and_return('current-hub')
    }

    context 'hub is current hub' do
      it 'returns the expected tag' do
        expect(hubs.current_hub_tag('current-hub')).to eq(' [current]')
      end
    end

    context 'hub is not current hub' do
      it 'returns the expected tag' do
        expect(hubs.current_hub_tag('not-current-hub')).to eq('')
      end
    end
  end

  describe '.config_key_regex' do
    it 'returns the expected regex' do
      expect(hubs.config_keys_regex).to eq('(?:api\\.base\\.url|github\\.user|token|user\\.agent\\.base)')
    end
  end

  describe '.config_api_base_url' do
    context 'when a github api base url is already saved' do
      before do
        Zenflow::Github.should_receive(:api_base_url).and_return('api-base-url')
      end

      context 'and the user decides to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('n')
        end

        it 'asks for an api base url' do
          Zenflow::Github.should_receive(:set_api_base_url)
          hubs.config_api_base_url('my-hub')
        end
      end

      context 'and the user decides not to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('y')
        end

        it 'does not ask for an api base url' do
          Zenflow::Github.should_not_receive(:set_api_base_url)
          hubs.config_api_base_url('my-hub')
        end
      end
    end

    context 'when an api base url is not already saved' do
      before do
        Zenflow::Github.should_receive(:api_base_url).and_return(nil)
      end

      it 'asks for an api base url' do
        Zenflow::Github.should_receive(:set_api_base_url)
        hubs.config_api_base_url('my-hub')
      end
    end
  end

  describe '.config_user' do
    context 'when a github user is already saved' do
      before do
        Zenflow::Github.should_receive(:user).and_return('user')
      end

      context 'and the user decides to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('n')
        end

        it 'asks for a user' do
          Zenflow::Github.should_receive(:set_user)
          hubs.config_user('my-hub')
        end
      end

      context 'and the user decides not to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('y')
        end

        it 'does not ask for a user' do
          Zenflow::Github.should_not_receive(:set_user)
          hubs.config_user('my-hub')
        end
      end
    end

    context 'when a user is not already saved' do
      before do
        Zenflow::Github.should_receive(:user).and_return(nil)
      end

      it 'asks for a user' do
        Zenflow::Github.should_receive(:set_user)
        hubs.config_user('my-hub')
      end
    end
  end

  describe '.config_user_agent_base' do
    context 'when a github user agent base is already saved' do
      before do
        Zenflow::Github.should_receive(:user_agent_base).and_return('user-agent-base')
      end

      context 'and the user decides to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('n')
        end

        it 'asks for a user agent base' do
          Zenflow::Github.should_receive(:set_user_agent_base)
          hubs.config_user_agent_base('my-hub')
        end
      end

      context 'and the user decides not to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('y')
        end

        it 'does not ask for a user agent base' do
          Zenflow::Github.should_not_receive(:set_user_agent_base)
          hubs.config_user_agent_base('my-hub')
        end
      end
    end

    context 'when a user agent base is not already saved' do
      before do
        Zenflow::Github.should_receive(:user_agent_base).and_return(nil)
      end

      it 'asks for a user agent base' do
        Zenflow::Github.should_receive(:set_user_agent_base)
        hubs.config_user_agent_base('my-hub')
      end
    end
  end
end
