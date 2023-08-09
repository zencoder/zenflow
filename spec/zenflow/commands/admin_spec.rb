require 'spec_helper'

describe Zenflow::Admin do
  let(:admin) { Zenflow::Admin.new }

  describe '.list' do
    it 'lists recognized hubs in git config' do
      expect(Zenflow::Shell).to receive(:run).with("git config --get-regexp zenflow\.hub\..*", silent: true).and_return(
<<EOS
zenflow.hub.hub.1.api.base.url api_base_url
zenflow.hub.yet.another.hub.github.user github_user
zenflow.hub.hub.1.token token
zenflow.hub.my-hub.token token
zenflow.hub.one.more.hub.user.agent.base user_agent_base
zenflow.hub.bad.token.hub.goobers user_agent_base
EOS
      )
      expect(Zenflow).to receive(:Log).with("Recogized hubs")
      expect(Terminal::Table).to receive(:new).with(
        headings: ["Hub"],
        rows: [
          ["github.com [default] [current]"],
          ["hub.1"],
          ["my-hub"],
          ["one.more.hub"],
          ["yet.another.hub"]
        ]
      ).and_return("log-data")
      expect(Zenflow).to receive(:Log).with("log-data", indent: false, arrows: false, color: false)
      admin.list
    end
  end

  describe '.current' do
    it 'logs the hubs of the current project' do
      expect(Zenflow).to receive(:Log).with("This project's hub is github.com [default] [current]")
      admin.current
    end
  end

  describe '.describe' do
    it 'displays config parameters for the hub' do
      hub = Zenflow::Github.new('my-hub')
      expect(admin).to receive(:resolve_hub).with('my-hub').and_return(hub)
      expect(admin).to receive(:hub_label).with('my-hub').and_return('my-hub')
      expect(Zenflow).to receive(:Log).with("Configuration details for hub my-hub")
      expect(hub).to receive(:describe).and_return([
        ["Parameter 1", "Github Config Key 1", "Github Conifg Value 1", "Value 1"],
        ["Parameter 2", "Github Config Key 2", "Github Conifg Value 2", "Value 2"],
        ["Parameter 3", "Github Config Key 3", "Github Conifg Value 3", "Value 3"]
      ])
      expect(Terminal::Table).to receive(:new).with(
        headings: ["Parameter", "Github Config Key", "Github Config Value", "Value (with system defaults)"],
        rows: [
          ["Parameter 1", "Github Config Key 1", "Github Conifg Value 1", "Value 1"],
          ["Parameter 2", "Github Config Key 2", "Github Conifg Value 2", "Value 2"],
          ["Parameter 3", "Github Config Key 3", "Github Conifg Value 3", "Value 3"]
        ]
      ).and_return("log-data")
      expect(Zenflow).to receive(:Log).with("log-data", {:indent=>false, :arrows=>false, :color=>false})
      admin.describe('my-hub')
    end
  end

  describe '.config' do
    context 'when called with a hub parameter' do
      it 'calls the individual parameter config methods' do
        myhub = Zenflow::Github.new('my-hub')
        expect(Zenflow::Github).to receive(:new).with('my-hub').and_return(myhub)
        expect(admin).to receive(:hub_label).with('my-hub').and_return('my-hub')
        expect(Zenflow).to receive(:Log).with("Configuring my-hub")
        expect(myhub).to receive(:config)
        admin.config('my-hub')
      end
    end

    context 'when called with no hub parameter' do
      it 'calls the individual parameter config methods' do
        expect(admin).to receive(:hub_label).with('github.com').and_return('github.com')
        expect(Zenflow).to receive(:Log).with("Configuring github.com")
        expect(Zenflow::Github::CURRENT).to receive(:config)
        admin.config
      end
    end
  end

  describe '.authorize' do
    context 'when called with a hub parameter' do
      it 'call the hubs authorize method' do
        myhub = Zenflow::Github.new('my-hub')
        expect(Zenflow::Github).to receive(:new).with('my-hub').and_return(myhub)
        expect(admin).to receive(:hub_label).with('my-hub').and_return('my-hub')
        expect(Zenflow).to receive(:Log).with("Authorizing my-hub")
        expect(myhub).to receive(:authorize)
        admin.authorize('my-hub')
      end
    end

    context 'when called with no hub parameter' do
      it 'call the current hubs authorize method' do
        expect(admin).to receive(:hub_label).with('github.com').and_return('github.com')
        expect(Zenflow).to receive(:Log).with("Authorizing github.com")
        expect(Zenflow::Github::CURRENT).to receive(:authorize)
        admin.authorize
      end
    end
  end

  describe '.resolve_hub' do
    context 'hub is not nil' do
      it 'resolves to the supplied hub' do
        expect(admin.resolve_hub('my-hub').hub).to eq('my-hub')
      end
    end

    context 'hub is nil' do
      it 'resolves to the CURRENT hub' do
        expect(admin.resolve_hub).to eq(Zenflow::Github::CURRENT)
      end
    end
  end

  describe '.hub_label' do
    context 'hub is default hub' do
      context 'hub is current hub' do
        before(:each){
          stub_const("Zenflow::Github::CURRENT", Zenflow::Github.new(Zenflow::Github::DEFAULT_HUB))
        }

        it 'returns the expected label' do
          expect(admin.hub_label(Zenflow::Github::DEFAULT_HUB)).to eq("#{Zenflow::Github::DEFAULT_HUB} [default] [current]")
        end
      end

      context 'hub is not current hub' do
        before(:each){
          stub_const("Zenflow::Github::CURRENT", Zenflow::Github.new('current-hub'))
        }

        it 'returns the expected label' do
          expect(admin.hub_label(Zenflow::Github::DEFAULT_HUB)).to eq("#{Zenflow::Github::DEFAULT_HUB} [default]")
        end
      end
    end

    context 'hub is not default hub' do
      before(:each){
        stub_const("Zenflow::Github::CURRENT", Zenflow::Github.new('current-hub'))
      }

      context 'hub is current hub' do
        it 'returns the expected label' do
          expect(admin.hub_label('current-hub')).to eq('current-hub [current]')
        end
      end

      context 'hub is not current hub' do
        it 'returns the expected label' do
          expect(admin.hub_label('not-current-hub')).to eq('not-current-hub')
        end
      end
    end
  end

  describe '.default_hub_tag' do
    context 'hub is default hub' do
      it 'returns the expected tag' do
        expect(admin.default_hub_tag(Zenflow::Github::DEFAULT_HUB)).to eq(' [default]')
      end
    end

    context 'hub is not default hub' do
      it 'returns the expected tag' do
        expect(admin.default_hub_tag('not-default-hub')).to eq('')
      end
    end
  end

  describe '.current_hub_tag' do
    before(:each){
      stub_const("Zenflow::Github::CURRENT", Zenflow::Github.new('current-hub'))
    }

    context 'hub is current hub' do
      it 'returns the expected tag' do
        expect(admin.current_hub_tag('current-hub')).to eq(' [current]')
      end
    end

    context 'hub is not current hub' do
      it 'returns the expected tag' do
        expect(admin.current_hub_tag('not-current-hub')).to eq('')
      end
    end
  end

  describe '.config_key_regex' do
    it 'returns the expected regex' do
      expect(admin.config_keys_regex).to eq('(?:api\\.base\\.url|github\\.user|token|user\\.agent\\.base)')
    end
  end
end
