require 'spec_helper'

describe Zenflow::Repo do
  describe 'with an SSH URL' do
    let(:url) { "git@github.com:zencoder/zenflow.git" }
    describe '.hub' do
      before(:each){
        Zenflow::Repo.should_receive(:url).exactly(3).times.and_return(url)
      }

      it 'selects the hub from the git remote -v url' do
        expect(Zenflow::Repo.hub).to eq("github.com")
      end
    end

    describe '.slug' do
      before(:each){
        Zenflow::Repo.should_receive(:url).exactly(3).times.and_return(url)
      }

      it 'selects the repo slug from the git remote -v url' do
        expect(Zenflow::Repo.slug).to eq("zencoder/zenflow")
      end
    end
  end

  describe 'with an HTTPS URL' do
    let(:url) { "https://github.com/zencoder/zenflow.git" }
    describe '.hub' do
      before(:each){
        Zenflow::Repo.should_receive(:url).exactly(3).times.and_return(url)
      }

      it 'selects the hub from the git remote -v url' do
        expect(Zenflow::Repo.hub).to eq("github.com")
      end
    end

    describe '.slug' do
      before(:each){
        Zenflow::Repo.should_receive(:url).exactly(3).times.and_return(url)
      }

      it 'selects the repo slug from the git remote -v url' do
        expect(Zenflow::Repo.slug).to eq("zencoder/zenflow")
      end
    end
  end
end
