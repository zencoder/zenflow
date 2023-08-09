require 'spec_helper'

describe Zenflow::Repo do
  describe '.hub' do
    before(:each){  
      expect(Zenflow::Repo).to receive(:url).twice.and_return("git@github.com:zencoder/zenflow.git")
    }

    it 'selects the hub from the git remote -v url' do
      expect(Zenflow::Repo.hub).to eq("github.com")
    end
  end

  describe '.slug' do
    before(:each){  
      expect(Zenflow::Repo).to receive(:url).twice.and_return("git@github.com:zencoder/zenflow.git")
    }

    it 'selects the repo slug from the git remote -v url' do
      expect(Zenflow::Repo.slug).to eq("zencoder/zenflow")
    end
  end
end
