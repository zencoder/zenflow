require 'spec_helper'

describe Zenflow::Deploy do

  describe "Zenflow.Deploy" do
    context 'with migrations' do
      it 'deploys with migrations' do
        Zenflow::Branch.should_receive(:push).with('some-server')
        Zenflow.should_receive(:Log).with("Deploying with migrations to some-server")
        Zenflow::Shell.should_receive(:run).with("cap some-server deploy:migrations")
        Zenflow::Deploy('some-server', :migrations => true)
      end
    end

    context 'without migrations' do
      it 'deploys without migrations' do
        Zenflow::Branch.should_receive(:push).with('some-server')
        Zenflow.should_receive(:Log).with("Deploying to some-server")
        Zenflow::Shell.should_receive(:run).with("cap some-server deploy")
        Zenflow::Deploy('some-server')
      end
    end
  end

  subject {Zenflow::Deploy.new}

  describe '#qa' do
    it 'Deploys to QA' do
      Zenflow.should_receive(:Deploy).with('qa', {})
      subject.qa
    end
  end

  describe '#staging' do
    it 'Deploys to staging' do
      Zenflow.should_receive(:Deploy).with('staging', {})
      subject.staging
    end
  end

  describe '#staging' do
    it 'Deploys to production' do
      Zenflow.should_receive(:Deploy).with('production', {})
      subject.production
    end
  end

end
