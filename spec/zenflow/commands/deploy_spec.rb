require 'spec_helper'

describe Zenflow::Deploy do

  describe "Zenflow.Deploy" do
    context 'with migrations' do
      it 'deploys with migrations' do
        expect(Zenflow::Branch).to receive(:push).with('some-server')
        expect(Zenflow).to receive(:Log).with("Deploying with migrations to some-server")
        expect(Zenflow::Shell).to receive(:run).with("cap some-server deploy:migrations")
        Zenflow::Deploy('some-server', :migrations => true)
      end
    end

    context 'without migrations' do
      it 'deploys without migrations' do
        expect(Zenflow::Branch).to receive(:push).with('some-server')
        expect(Zenflow).to receive(:Log).with("Deploying to some-server")
        expect(Zenflow::Shell).to receive(:run).with("cap some-server deploy")
        Zenflow::Deploy('some-server')
      end
    end

    context 'with trace' do
      it 'deploys with trace' do
        Zenflow::Branch.should_receive(:push).with('some-server')
        Zenflow.should_receive(:Log).with("Deploying to some-server")
        Zenflow::Shell.should_receive(:run).with("cap some-server deploy --trace")
        Zenflow::Deploy('some-server', :trace => true)
      end
    end
  end

  subject {Zenflow::Deploy.new}

  describe '#qa' do
    it 'Deploys to QA' do
      expect(Zenflow).to receive(:Deploy).with('qa', {})
      subject.qa
    end
  end

  describe '#staging' do
    it 'Deploys to staging' do
      expect(Zenflow).to receive(:Deploy).with('staging', {})
      subject.staging
    end
  end

  describe '#staging' do
    it 'Deploys to production' do
      expect(Zenflow).to receive(:Deploy).with('production', {})
      subject.production
    end
  end

end
