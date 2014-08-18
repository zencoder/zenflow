require 'spec_helper'

describe Zenflow::Github do
  describe '.api_base_url' do
    context 'when the value is present' do
      let(:hub) { Zenflow::Github.new('test-hub') }

      before(:each){
        hub.should_receive(:get_config).with('api.base.url').and_return("api-base-url")
      }

      context 'and use_default_when_value_is_nil is not specified' do
        it 'returns the expected value' do
          expect(hub.api_base_url).to eq("api-base-url")
        end
      end

      context 'and use_default_when_value_is_nil is true' do
        it 'returns the expected value' do
          expect(hub.api_base_url(true)).to eq("api-base-url")
        end
      end

      context 'and use_default_when_value_is_nil is false' do
        it 'returns the expected value' do
          expect(hub.api_base_url(false)).to eq("api-base-url")
        end
      end
    end

    context 'when the value is absent' do
      let(:hub) { Zenflow::Github.new('test-hub') }

      before(:each){
        hub.should_receive(:get_config).with('api.base.url').and_return(nil)
      }

      context 'and use_default_when_value_is_nil is not specified' do
        it 'returns the expected value' do
          expect(hub.api_base_url).to eq("https://api.github.com")
        end
      end

      context 'and use_default_when_value_is_nil is true' do
        it 'returns the expected value' do
          expect(hub.api_base_url(true)).to eq("https://api.github.com")
        end
      end

      context 'and use_default_when_value_is_nil is false' do
        it 'returns the expected value' do
          expect(hub.api_base_url(false)).to eq(nil)
        end
      end
    end
  end

  describe '.set_api_base_url' do

    it 'asks for the API base URL and sets it to zenflow.api.base.url' do
    end
  end

  describe '.set_api_base_url' do
    let(:hub){Zenflow::Github.new('test-hub')}
    let(:api_base_url){'api-base-url'}

    context 'when a github api base url is already saved' do
      before do
        hub.should_receive(:api_base_url).twice.and_return(api_base_url)
      end

      context 'and the user decides to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('n')
        end

        it 'asks for an api base url' do
          Zenflow.should_receive(:Ask).and_return(api_base_url)
          hub.should_receive(:set_config).with('api.base.url', api_base_url)
          hub.set_api_base_url
        end
      end

      context 'and the user decides not to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('y')
        end

        it 'does not ask for an api base url' do
          Zenflow.should_not_receive(:Ask)
          hub.should_not_receive(:set_config)
          hub.set_api_base_url
        end
      end
    end

    context 'when an api base url is not already saved' do
      before do
        hub.should_receive(:api_base_url).and_return(nil)
      end

      it 'asks for an api base url' do
        Zenflow.should_receive(:Ask).and_return(api_base_url)
        hub.should_receive(:set_config).with('api.base.url', api_base_url)
        hub.set_api_base_url
      end
    end
  end

  describe '.user' do
    let(:hub){Zenflow::Github.new('hub')}
    let(:user){'github-user'}

    before(:each){
      hub.should_receive(:get_config).with('github.user').and_return(user)
    }

    it "returns the user" do
      expect(hub.user).to eq(user)
    end
  end

  describe '.set_user' do
    let(:hub){Zenflow::Github.new('test-hub')}
    let(:user){'github-user'}

    context 'when a github user is already saved' do
      before do
        hub.should_receive(:user).twice.and_return(user)
      end

      context 'and the user decides to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('n')
        end

        it 'asks for a user' do
          Zenflow.should_receive(:Ask).and_return(user)
          hub.should_receive(:set_config).with('github.user', user)
          hub.set_user
        end
      end

      context 'and the user decides not to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('y')
        end

        it 'does not ask for a user' do
          Zenflow.should_not_receive(:Ask)
          hub.should_not_receive(:set_config)
          hub.set_user
        end
      end
    end

    context 'when a user is not already saved' do
      before do
        hub.should_receive(:user).and_return(nil)
      end

      it 'asks for a user' do
        Zenflow.should_receive(:Ask).and_return(user)
        hub.should_receive(:set_config).with('github.user', user)
        hub.set_user
      end
    end
  end

  describe '.authorize' do
    let(:hub){Zenflow::Github.new('my-hub')}

    context 'when a zenflow_token is already saved' do
      before do
        hub.should_receive(:zenflow_token).and_return('super secret token')
      end

      context 'and the user decides to set a new one' do
        before do
          Zenflow.should_receive(:Ask).with("You already have a token from GitHub. Do you want to set a new one?", :options => ["y", "N"], :default => "n").and_return('y')
        end

        context 'and authorization succeeds' do
          before do
            Zenflow.should_receive("Log").with("Authorizing with GitHub (adamkittelson@my-hub)... Enter your GitHub password.")
            hub.should_receive(:user).twice.and_return('adamkittelson')
            hub.should_receive(:api_base_url).and_return('https://api.base.url')
            Zenflow::Shell.should_receive(:run).with(%{curl -u "adamkittelson" https://api.base.url/authorizations -d '{"scopes":["repo"], "note":"Zenflow"}' --silent}, :silent => true).and_return('{"token": "super secure token"}')
          end

          it 'authorizes with Github' do
            hub.should_receive(:set_config).with('token', "super secure token")
            Zenflow.should_receive("Log").with("Authorized!")
            hub.authorize
          end
        end

        context 'and authorization fails' do
          before do
            Zenflow.should_receive("Log").with("Authorizing with GitHub (adamkittelson@my-hub)... Enter your GitHub password.")
            hub.should_receive(:user).twice.and_return('adamkittelson')
            hub.should_receive(:api_base_url).and_return('https://api.base.url')
            Zenflow::Shell.should_receive(:run).with(%{curl -u "adamkittelson" https://api.base.url/authorizations -d '{"scopes":["repo"], "note":"Zenflow"}' --silent}, :silent => true).and_return('{"message": "failed to authorize, bummer"}')
          end

          it 'authorizes with Github' do
            Zenflow.should_receive("Log").with("Something went wrong. Error from GitHub was: failed to authorize, bummer")
            hub.authorize
          end
        end
      end

      context 'and the user decides not to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('n')
        end

        it 'does not authorize with Github' do
          hub.authorize
        end
      end
    end

    context 'when a zenflow_token is not already saved' do
      before do
        hub.should_receive(:zenflow_token).and_return(nil)
      end

      context 'and authorization succeeds' do
        before do
          Zenflow.should_receive("Log").with("Authorizing with GitHub (adamkittelson@my-hub)... Enter your GitHub password.")
          hub.should_receive(:user).twice.and_return('adamkittelson')
          hub.should_receive(:api_base_url).and_return('https://api.base.url')
          Zenflow::Shell.should_receive(:run).with(%{curl -u "adamkittelson" https://api.base.url/authorizations -d '{"scopes":["repo"], "note":"Zenflow"}' --silent}, :silent => true).and_return('{"token": "super secure token"}')
        end

        it 'authorizes with Github' do
          hub.should_receive(:set_config).with('token', "super secure token")
          Zenflow.should_receive("Log").with("Authorized!")
          hub.authorize
        end
      end

      context 'and authorization fails' do
        before do
          Zenflow.should_receive("Log").with("Authorizing with GitHub (adamkittelson@my-hub)... Enter your GitHub password.")
          hub.should_receive(:user).twice.and_return('adamkittelson')
          hub.should_receive(:api_base_url).and_return('https://api.base.url')
          Zenflow::Shell.should_receive(:run).with(%{curl -u "adamkittelson" https://api.base.url/authorizations -d '{"scopes":["repo"], "note":"Zenflow"}' --silent}, :silent => true).and_return('{"message": "failed to authorize, bummer"}')
        end

        it 'does not authorize with Github' do
          Zenflow.should_receive("Log").with("Something went wrong. Error from GitHub was: failed to authorize, bummer")
          hub.authorize
        end
      end
    end
  end

  describe '.user_agent_base' do
    let(:hub){Zenflow::Github.new('hub')}

    context 'when the value is present' do
      before(:each){
        hub.should_receive(:get_config).with('user.agent.base').and_return("user-agent-base")
      }

      context 'and use_default_when_value_is_nil is not specified' do
        it 'returns the expected value' do
          expect(hub.user_agent_base).to eq("user-agent-base")
        end
      end

      context 'and use_default_when_value_is_nil is true' do
        it 'returns the expected value' do
          expect(hub.user_agent_base(true)).to eq("user-agent-base")
        end
      end

      context 'and use_default_when_value_is_nil is false' do
        it 'returns the expected value' do
          expect(hub.user_agent_base(false)).to eq("user-agent-base")
        end
      end
    end

    context 'when the value is absent' do
      before(:each){
        hub.should_receive(:get_config).with('user.agent.base').and_return(nil)
      }

      context 'and use_default_when_value_is_nil is not specified' do
        it 'returns the expected value' do
          expect(hub.user_agent_base).to eq("Zencoder")
        end
      end

      context 'and use_default_when_value_is_nil is true' do
        it 'returns the expected value' do
          expect(hub.user_agent_base(true)).to eq("Zencoder")
        end
      end

      context 'and use_default_when_value_is_nil is false' do
        it 'returns the expected value' do
          expect(hub.user_agent_base(false)).to eq(nil)
        end
      end
    end
  end

  describe '.set_user_agent_base' do
    let(:hub){Zenflow::Github.new('test-hub')}
    let(:user_agent_base){'user-agent-base'}

    context 'when a github user agent base is already saved' do
      before do
        hub.should_receive(:user_agent_base).twice.and_return(user_agent_base)
      end

      context 'and the user decides to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('n')
        end

        it 'asks for a user agent base' do
          Zenflow.should_receive(:Ask).and_return(user_agent_base)
          hub.should_receive(:set_config).with('user.agent.base', user_agent_base)
          hub.set_user_agent_base
        end
      end

      context 'and the user decides not to set a new one' do
        before do
          Zenflow.should_receive(:Ask).and_return('y')
        end

        it 'does not ask for a user agent base' do
          Zenflow.should_not_receive(:Ask)
          hub.should_not_receive(:set_config)
          hub.set_user_agent_base
        end
      end
    end

    context 'when a user agent base is not already saved' do
      before do
        hub.should_receive(:user_agent_base).and_return(nil)
      end

      it 'asks for a user agent base' do
        Zenflow.should_receive(:Ask).and_return(user_agent_base)
        hub.should_receive(:set_config).with('user.agent.base', user_agent_base)
        hub.set_user_agent_base
      end
    end
  end

  describe '.current' do
    context 'when the current repo is nil' do
      before(:each){
        Zenflow::Repo.should_receive(:hub).and_return(nil)
      }

      it 'returns the default hub' do
        expect(Zenflow::Github.current.hub).to eq 'github.com'
      end    
    end

    context 'when the current repo is not nil' do
      before(:each){
        Zenflow::Repo.should_receive(:hub).and_return('current.repo.hub')
      }

      it 'returns the current repo\'s hub' do
        expect(Zenflow::Github.current.hub).to eq 'current.repo.hub'
      end    
    end
  end

  describe '.parameter_key_for_hub' do

    context 'when hub is the default hub' do
      let(:hub){Zenflow::Github.new('github.com')}

      context 'and key is the api url base key' do
        it 'prepends \'zenflow\' as a prefix' do
          expect(hub.parameter_key_for_hub('api.base.url')).to eq("zenflow.api.base.url")
        end
      end

      context 'and key is the user key' do
        it 'does not prepend a prefix' do
          expect(hub.parameter_key_for_hub('github.user')).to eq('github.user')
        end
      end

      context 'and key is the zenflow token key' do
        it 'prepends \'zenflow\' as a prefix' do
          expect(hub.parameter_key_for_hub('token')).to eq("zenflow.token")
        end
      end

      context 'and key is the user agent base key' do
        it 'prepends \'zenflow\' as a prefix' do
          expect(hub.parameter_key_for_hub('user.agent.base')).to eq("zenflow.user.agent.base")
        end
      end
    end

    context 'hub is not the default hub' do
      let(:hub){Zenflow::Github.new('my-hub')}

      context 'and key is the api url base key' do
        it 'prepends a hub-specific prefix' do
          expect(hub.parameter_key_for_hub('api.base.url')).to eq("zenflow.hub.my-hub.api.base.url")
        end
      end

      context 'and key is the user key' do
        it 'prepends a hub-specific prefix' do
          expect(hub.parameter_key_for_hub('github.user')).to eq("zenflow.hub.my-hub.github.user")
        end
      end

      context 'and key is the zenflow token key' do
        it 'prepends a hub-specific prefix' do
          expect(hub.parameter_key_for_hub('token')).to eq("zenflow.hub.my-hub.token")
        end
      end

      context 'and key is the user agent base key' do
        it 'prepends a hub-specific prefix' do
          expect(hub.parameter_key_for_hub('user.agent.base')).to eq("zenflow.hub.my-hub.user.agent.base")
        end
      end
    end
  end

  describe '.get_config' do
    let(:hub){Zenflow::Github.new('test-hub')}

    it 'gets the correct global config parameter' do
      hub.should_receive(:get_global_config).with("zenflow.hub.test-hub.test-key")
      hub.get_config('test-key')
    end
  end

  describe '.set_config' do
    let(:hub){Zenflow::Github.new('test-hub')}

    it 'sets the correct global config parameter' do
      hub.should_receive(:set_global_config).with("zenflow.hub.test-hub.test-key", "test-value")
      hub.set_config('test-key', 'test-value')
    end
  end

  describe '.get_global_config' do
    let(:hub){Zenflow::Github.new('test-hub')}

    context 'when value is present' do
      before(:each){
        Zenflow::Shell.should_receive(:run).with('git config --get key', silent: true).and_return('value')
      }

      it 'returns the value' do
        expect(hub.get_global_config('key')).to eq('value')
      end
    end

    context 'when value is missing' do
      before(:each){
        Zenflow::Shell.should_receive(:run).with('git config --get key', silent: true).and_return('')
      }

      it 'returns nil' do
        expect(hub.get_global_config('key')).to eq(nil)
      end
    end
  end

  describe '.set_global_config' do
    let(:hub){Zenflow::Github.new('test-hub')}

    before(:each){
      Zenflow::Shell.should_receive(:run).with('git config --global key value', silent: true)
    }

    it 'sets the value' do
      hub.set_global_config('key', 'value')
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

  describe '.describe_parameter' do
    let(:hub){Zenflow::Github.new('my-hub')}

    it 'returns the expected array' do
      hub.should_receive(:get_config).with('key').and_return('config-value')

      expect(hub.describe_parameter('name', 'key', 'value')).to eq(
        ['name', 'zenflow.hub.my-hub.key', 'config-value', 'value']
      )
    end
  end

  describe '.describe' do
    context 'all parameters configured' do
      let(:hub){Zenflow::Github.new('my-hub')}

      it 'returns the expected data' do
        hub.should_receive(:get_config).twice.with('api.base.url').and_return('api-base-url-config-value')
        hub.should_receive(:get_config).twice.with('github.user').and_return('github-user-config-value')
        hub.should_receive(:get_config).twice.with('token').and_return('token-config-value')
        hub.should_receive(:get_config).twice.with('user.agent.base').and_return('user-agent-base-config-value')

        expect(hub.describe).to eq([
          ['API Base URL',    'zenflow.hub.my-hub.api.base.url',    'api-base-url-config-value',    'api-base-url-config-value'],
          ['User',            'zenflow.hub.my-hub.github.user',     'github-user-config-value',     'github-user-config-value'],
          ['Token',           'zenflow.hub.my-hub.token',           'token-config-value',           'token-config-value'],
          ['User Agent Base', 'zenflow.hub.my-hub.user.agent.base', 'user-agent-base-config-value', 'user-agent-base-config-value']
        ])
      end
    end

    context 'no parameters configured' do
      let(:hub){Zenflow::Github.new('my-hub')}

      it 'returns the expected data' do
        hub.should_receive(:get_config).twice.with('api.base.url').and_return(nil)
        hub.should_receive(:get_config).twice.with('github.user').and_return(nil)
        hub.should_receive(:get_config).twice.with('token').and_return(nil)
        hub.should_receive(:get_config).twice.with('user.agent.base').and_return(nil)

        expect(hub.describe).to eq([
          ['API Base URL',    'zenflow.hub.my-hub.api.base.url',    nil, 'https://api.github.com'],
          ['User',            'zenflow.hub.my-hub.github.user',     nil, nil],
          ['Token',           'zenflow.hub.my-hub.token',           nil, nil],
          ['User Agent Base', 'zenflow.hub.my-hub.user.agent.base', nil, 'Zencoder']
        ])
      end
    end

    context 'hub is default' do
      let(:hub){Zenflow::Github.new(Zenflow::Github::DEFAULT_HUB)}

      it 'returns the expected data' do
        hub.should_receive(:get_config).twice.with('api.base.url').and_return(nil)
        hub.should_receive(:get_config).twice.with('github.user').and_return(nil)
        hub.should_receive(:get_config).twice.with('token').and_return(nil)
        hub.should_receive(:get_config).twice.with('user.agent.base').and_return(nil)

        expect(hub.describe).to eq([
          ['API Base URL',    'zenflow.api.base.url',    nil, 'https://api.github.com'],
          ['User',            'github.user',             nil, nil],
          ['Token',           'zenflow.token',           nil, nil],
          ['User Agent Base', 'zenflow.user.agent.base', nil, 'Zencoder']
        ])
      end
    end
  end
end
