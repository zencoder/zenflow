require 'spec_helper'

describe Zenflow::Repo do
  describe '.hub' do
    before(:each){  
      Zenflow::Repo.should_receive(:url).twice.and_return("git@github.com:zencoder/zenflow.git")
    }

    it 'selects the hub from the git remote -v url' do
      expect(Zenflow::Repo.hub).to eq("github.com")
    end
  end

  describe '.slug' do
    before(:each){  
      Zenflow::Repo.should_receive(:url).twice.and_return("git@github.com:zencoder/zenflow.git")
    }

    it 'selects the repo slug from the git remote -v url' do
      expect(Zenflow::Repo.slug).to eq("zencoder/zenflow")
    end
  end

  describe '.is_current_hub?' do
    before(:each){  
      Zenflow::Repo.should_receive(:url).twice.and_return("git@github.com:zencoder/zenflow.git")
    }

    context 'when check matches hub' do
      it 'returns true' do
        expect(Zenflow::Repo.is_current_hub?("github.com")).to eq(true)
      end
    end

    context 'when check does not match hub' do
      it 'returns false' do
        expect(Zenflow::Repo.is_current_hub?("my-hub")).to eq(false)
      end
    end
  end

  describe '.is_default_hub?' do
    context 'when check is not supplied' do
      context 'and current hub matches default hub' do
        before(:each){  
          Zenflow::Repo.should_receive(:url).twice.and_return("git@github.com:zencoder/zenflow.git")
        }

        it 'returns true' do
          expect(Zenflow::Repo.is_default_hub?).to eq(true)
        end
      end

      context 'and current hub does not match default hub' do
        before(:each){  
          Zenflow::Repo.should_receive(:url).twice.and_return("git@my-hub:zencoder/zenflow.git")
        }

        it 'returns true' do
          expect(Zenflow::Repo.is_default_hub?).to eq(false)
        end
      end
    end

    context 'when check is supplied' do
      context 'and check matches default hub' do
        it 'returns true' do
          expect(Zenflow::Repo.is_default_hub?("github.com")).to eq(true)
        end
      end

      context 'and check does not match default hub' do
        it 'returns false' do
          expect(Zenflow::Repo.is_default_hub?("my-hub")).to eq(false)
        end
      end
    end
  end
end
