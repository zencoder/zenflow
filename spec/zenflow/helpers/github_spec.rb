require 'spec_helper'

describe Zenflow::Github do
  describe '.api_base_url' do
    context 'when the value is present' do
      before(:each){
        Zenflow::Github.should_receive(:get_config_for_hub).with('test-hub', 'api.base.url').and_return("api-base-url")
      }

      context 'and default is true' do
        it 'returns the expected value' do
          expect(Zenflow::Github.api_base_url('test-hub', true)).to eq("api-base-url")
        end
      end

      context 'and default is false' do
        it 'returns the expected value' do
          expect(Zenflow::Github.api_base_url('test-hub', false)).to eq("api-base-url")
        end
      end
    end

    context 'when the value is absent' do
      before(:each){
        Zenflow::Github.should_receive(:get_config_for_hub).with('test-hub', 'api.base.url').and_return(nil)
      }

      context 'and default is true' do
        it 'returns the expected value' do
          expect(Zenflow::Github.api_base_url('test-hub', true)).to eq("https://api.github.com")
        end
      end

      context 'and default is false' do
        it 'returns the expected value' do
          expect(Zenflow::Github.api_base_url('test-hub', false)).to eq(nil)
        end
      end
    end
  end

  describe '.set_api_base_url' do
    let(:api_base_url){'api-base-url'}

    it 'asks for the API base URL and sets it to zenflow.api.base.url' do
      Zenflow.should_receive(:Ask).and_return(api_base_url)
      Zenflow::Github.should_receive(:set_config_for_hub).with(nil, 'api.base.url', api_base_url)
      Zenflow::Github.set_api_base_url
    end
  end

  describe '.user' do
    let(:user){'github-user'}

    before(:each){
      Zenflow::Github.should_receive(:get_config_for_hub).with('test-hub', 'github.user').and_return(user)
    }

    it "returns the user" do
      expect(Zenflow::Github.user('test-hub')).to eq(user)
    end
  end

  describe '.set_user' do
    let(:user){'github-user'}

    it 'asks for the user name and sets it to github.user' do
      Zenflow.should_receive(:Ask).and_return(user)
      Zenflow::Github.should_receive(:set_config_for_hub).with(nil, 'github.user', user)
      Zenflow::Github.set_user
    end
  end

  describe '.authorize' do
    context "when authorization fails" do
      before do
        Zenflow.should_receive("Log").with("Authorizing with GitHub (adamkittelson@github.com)... Enter your GitHub password.")
        Zenflow::Github.should_receive(:user).twice.and_return('adamkittelson')
        Zenflow::Github.should_receive(:api_base_url).and_return('https://api.base.url')
        Zenflow::Shell.should_receive(:run).with(%{curl -u "adamkittelson" https://api.base.url/authorizations -d '{"scopes":["repo"], "note":"Zenflow"}' --silent}, :silent => true).and_return('{"message": "failed to authorize, bummer"}')
      end

      it "logs that something went wrong" do
        Zenflow.should_receive("Log").with("Something went wrong. Error from GitHub was: failed to authorize, bummer")
        Zenflow::Github.authorize
      end
    end

    context "when authorization succeeds" do
      before do
        Zenflow.should_receive("Log").with("Authorizing with GitHub (adamkittelson@github.com)... Enter your GitHub password.")
        Zenflow::Github.should_receive(:user).twice.and_return('adamkittelson')
        Zenflow::Github.should_receive(:api_base_url).and_return('https://api.base.url')
        Zenflow::Shell.should_receive(:run).with(%{curl -u "adamkittelson" https://api.base.url/authorizations -d '{"scopes":["repo"], "note":"Zenflow"}' --silent}, :silent => true).and_return('{"token": "super secure token"}')
      end

      it "adds the token to git config and logs a happy message of success" do
        Zenflow::Github.should_receive(:set_config_for_hub).with(nil, 'token', "super secure token")
        Zenflow.should_receive("Log").with("Authorized!")
        Zenflow::Github.authorize
      end
    end

  end

  describe '.user_agent_base' do
    context 'when the value is present' do
      before(:each){
        Zenflow::Github.should_receive(:get_config_for_hub).with('test-hub', 'user.agent.base').and_return("user-agent-base")
      }

      context 'and default is true' do
        it 'returns the expected value' do
          expect(Zenflow::Github.user_agent_base('test-hub', true)).to eq("user-agent-base")
        end
      end

      context 'and default is false' do
        it 'returns the expected value' do
          expect(Zenflow::Github.user_agent_base('test-hub', false)).to eq("user-agent-base")
        end
      end
    end

    context 'when the value is absent' do
      before(:each){
        Zenflow::Github.should_receive(:get_config_for_hub).with('test-hub', 'user.agent.base').and_return(nil)
      }

      context 'and default is true' do
        it 'returns the expected value' do
          expect(Zenflow::Github.user_agent_base('test-hub', true)).to eq("Zencoder")
        end
      end

      context 'and default is false' do
        it 'returns the expected value' do
          expect(Zenflow::Github.user_agent_base('test-hub', false)).to eq(nil)
        end
      end
    end
  end

  describe '.set_user_agent_base' do
    let(:user_agent_base){'user-agent-base'}

    it 'asks for the User-Agent base string and sets it to zenflow.user.agent.base' do
      Zenflow.should_receive(:Ask).and_return(user_agent_base)
      Zenflow::Github.should_receive(:set_config_for_hub).with(nil, 'user.agent.base', user_agent_base)
      Zenflow::Github.set_user_agent_base
    end
  end

  describe '.resolve_hub' do
    context 'when supplied as argument' do
      it 'returns the hub provided' do
        expect(Zenflow::Github.resolve_hub('test-hub')).to eq 'test-hub'
      end    
    end

    context 'when argument is nil' do
      context 'and there is a repo hub' do
        before(:each){
          Zenflow::Repo.should_receive(:hub).and_return('repo-hub')
        }

        it 'returns the repo hub' do
          expect(Zenflow::Github.resolve_hub(nil)).to eq 'repo-hub'
        end    
      end

      context 'and the repo hub is nil' do
        before(:each){
          Zenflow::Repo.should_receive(:hub).and_return(nil)
        }

        it 'returns the default hub' do
          expect(Zenflow::Github.resolve_hub(nil)).to eq Zenflow::Github::DEFAULT_HUB
        end    
      end
    end
  end

  describe '.key_for_hub' do
    context 'when hub is the default hub' do
      context 'and key is the api url base key' do
        it 'prepends \'zenflow\' as a prefix' do
          expect(Zenflow::Github.key_for_hub('github.com', 'api.base.url')).to eq("zenflow.api.base.url")
        end
      end

      context 'and key is the user key' do
        it 'does not prepend a prefix' do
          expect(Zenflow::Github.key_for_hub('github.com', 'github.user')).to eq('github.user')
        end
      end

      context 'and key is the zenflow token key' do
        it 'prepends \'zenflow\' as a prefix' do
          expect(Zenflow::Github.key_for_hub('github.com', 'token')).to eq("zenflow.token")
        end
      end

      context 'and key is the user agent base key' do
        it 'prepends \'zenflow\' as a prefix' do
          expect(Zenflow::Github.key_for_hub('github.com', 'user.agent.base')).to eq("zenflow.user.agent.base")
        end
      end
    end

    context 'hub is not the default hub' do
      context 'and key is the api url base key' do
        it 'prepends a hub-specific prefix' do
          expect(Zenflow::Github.key_for_hub('my-hub', 'api.base.url')).to eq("zenflow.hub.my-hub.api.base.url")
        end
      end

      context 'and key is the user key' do
        it 'prepends a hub-specific prefix' do
          expect(Zenflow::Github.key_for_hub('my-hub', 'github.user')).to eq("zenflow.hub.my-hub.github.user")
        end
      end

      context 'and key is the zenflow token key' do
        it 'prepends a hub-specific prefix' do
          expect(Zenflow::Github.key_for_hub('my-hub', 'token')).to eq("zenflow.hub.my-hub.token")
        end
      end

      context 'and key is the user agent base key' do
        it 'prepends a hub-specific prefix' do
          expect(Zenflow::Github.key_for_hub('my-hub', 'user.agent.base')).to eq("zenflow.hub.my-hub.user.agent.base")
        end
      end
    end
  end

  describe '.get_config_for_hub' do
    it 'gets the correct global config parameter' do
      Zenflow::Github.should_receive(:get_global_config).with("zenflow.hub.test-hub.test-key")
      Zenflow::Github.get_config_for_hub('test-hub', 'test-key')
    end
  end

  describe '.set_config_for_hub' do
    it 'sets the correct global config parameter' do
      Zenflow::Github.should_receive(:set_global_config).with("zenflow.hub.test-hub.test-key", "test-value")
      Zenflow::Github.set_config_for_hub('test-hub', 'test-key', 'test-value')
    end
  end

  describe '.get_global_config' do
    context 'when value is present' do
      before(:each){
        Zenflow::Shell.should_receive(:run).with('git config --get key', silent: true).and_return('value')
      }

      it 'returns the value' do
        expect(Zenflow::Github.get_global_config('key')).to eq('value')
      end
    end

    context 'when value is missing' do
      before(:each){
        Zenflow::Shell.should_receive(:run).with('git config --get key', silent: true).and_return('')
      }

      it 'returns nil' do
        expect(Zenflow::Github.get_global_config('key')).to eq(nil)
      end
    end
  end

  describe '.set_global_config' do
    before(:each){
      Zenflow::Shell.should_receive(:run).with('git config --global key value', silent: true)
    }

    it 'sets the value' do
      Zenflow::Github.set_global_config('key', 'value')
    end
  end

  describe '.config_keys' do
    it 'returns the expected array of keys' do
      expect(Zenflow::Github::CONFIG_KEYS).to eq([
        'api.base.url',
        'github.user',
        'token',
        'user.agent.base'
      ])
    end
  end

  describe '.describe_hub_parameter' do
    it 'returns the expected array' do
      Zenflow::Github.should_receive(:get_config_for_hub).with('my-hub', 'key').and_return('config-value')
      expect(Zenflow::Github.describe_hub_parameter('name', 'my-hub', 'key', 'value')).to eq(
        ['name', 'zenflow.hub.my-hub.key', 'config-value', 'value']
      )
    end
  end

  describe '.describe_hub' do
    context 'all parameters configured' do
      it 'returns the expected data' do
        Zenflow::Github.should_receive(:get_config_for_hub).twice.with('my-hub', 'api.base.url').and_return('api-base-url-config-value')
        Zenflow::Github.should_receive(:get_config_for_hub).twice.with('my-hub', 'github.user').and_return('github-user-config-value')
        Zenflow::Github.should_receive(:get_config_for_hub).twice.with('my-hub', 'token').and_return('token-config-value')
        Zenflow::Github.should_receive(:get_config_for_hub).twice.with('my-hub', 'user.agent.base').and_return('user-agent-base-config-value')

        expect(Zenflow::Github.describe_hub('my-hub')).to eq([
          ['API Base URL',    'zenflow.hub.my-hub.api.base.url',    'api-base-url-config-value',    'api-base-url-config-value'],
          ['User',            'zenflow.hub.my-hub.github.user',     'github-user-config-value',     'github-user-config-value'],
          ['Token',           'zenflow.hub.my-hub.token',           'token-config-value',           'token-config-value'],
          ['User Agent Base', 'zenflow.hub.my-hub.user.agent.base', 'user-agent-base-config-value', 'user-agent-base-config-value']
        ])
      end
    end

    context 'no parameters configured' do
      it 'returns the expected data' do
        Zenflow::Github.should_receive(:get_config_for_hub).twice.with('my-hub', 'api.base.url').and_return(nil)
        Zenflow::Github.should_receive(:get_config_for_hub).twice.with('my-hub', 'github.user').and_return(nil)
        Zenflow::Github.should_receive(:get_config_for_hub).twice.with('my-hub', 'token').and_return(nil)
        Zenflow::Github.should_receive(:get_config_for_hub).twice.with('my-hub', 'user.agent.base').and_return(nil)

        expect(Zenflow::Github.describe_hub('my-hub')).to eq([
          ['API Base URL',    'zenflow.hub.my-hub.api.base.url',    nil, 'https://api.github.com'],
          ['User',            'zenflow.hub.my-hub.github.user',     nil, nil],
          ['Token',           'zenflow.hub.my-hub.token',           nil, nil],
          ['User Agent Base', 'zenflow.hub.my-hub.user.agent.base', nil, 'Zencoder']
        ])
      end
    end

    context 'hub is default' do
      it 'returns the expected data' do
        Zenflow::Github.should_receive(:get_config_for_hub).twice.with('github.com', 'api.base.url').and_return(nil)
        Zenflow::Github.should_receive(:get_config_for_hub).twice.with('github.com', 'github.user').and_return(nil)
        Zenflow::Github.should_receive(:get_config_for_hub).twice.with('github.com', 'token').and_return(nil)
        Zenflow::Github.should_receive(:get_config_for_hub).twice.with('github.com', 'user.agent.base').and_return(nil)

        expect(Zenflow::Github.describe_hub('github.com')).to eq([
          ['API Base URL',    'zenflow.api.base.url',    nil, 'https://api.github.com'],
          ['User',            'github.user',             nil, nil],
          ['Token',           'zenflow.token',           nil, nil],
          ['User Agent Base', 'zenflow.user.agent.base', nil, 'Zencoder']
        ])
      end
    end
  end
end
