require 'spec_helper'

describe Zenflow::Shell do
  describe '.failed!' do
    before(:all) { Zenflow::Shell.failed!(404) }
    it { expect(Zenflow::Shell.instance_variable_get('@failed')).to be_truthy }
    it { expect(Zenflow::Shell.instance_variable_get('@status')).to eq(404) }
  end

  describe '.failed?' do
    context 'when failed' do
      before(:all) { Zenflow::Shell.failed!('bad') }
      it { expect(Zenflow::Shell.failed?).to be_truthy }
    end

    context 'when not failed' do
      before(:all) { Zenflow::Shell.instance_variable_set('@failed', false) }
      it { expect(Zenflow::Shell.failed?).to be false }
    end
  end

  describe '.status' do
    context 'with a status' do
      before(:all) { Zenflow::Shell.instance_variable_set('@status', 200) }
      it { expect(Zenflow::Shell.status).to eq(200) }
    end

    context 'without a status' do
      before(:all) { Zenflow::Shell.instance_variable_set('@status', nil) }
      it { expect(Zenflow::Shell.status).to eq(0) }
    end
  end

  describe '.[]' do
    let(:command) { 'foo' }
    it 'runs the command' do
      expect(Zenflow::Shell).to receive(:run).with(command)
      Zenflow::Shell[command]
    end
  end

  describe '.run' do
    before(:all) { Zenflow::Shell.instance_variable_set('@failed', false) }

    context 'silent' do
      let(:command) { 'ls' }

      it 'runs the command' do
        expect(Zenflow::Shell).to receive(:run_without_output).with(command, { silent: true })
        Zenflow::Shell.run(command, silent: true)
      end

      it 'logs the command' do
        allow(Zenflow::Shell).to receive(:run_without_output).and_return(true)
        expect(Zenflow).to receive(:LogToFile).once.with("$ #{command}\n")
        Zenflow::Shell.run(command, silent: true)
      end
    end

    context 'noisy' do
      let(:command) { 'ls' }

      it 'runs the command' do
        allow(Zenflow).to receive(:Log)
        expect(Zenflow::Shell).to receive(:run_with_output).with(command, {})
        Zenflow::Shell.run(command)
      end

      it 'logs the command' do
        allow(Zenflow::Shell).to receive(:run_with_output).and_return(true)
        expect(Zenflow).to receive(:Log).once.with(
          "$ #{command}", arrows: false, color: :yellow
        )
        Zenflow::Shell.run(command)
      end
    end
  end

  describe '.run_with_output' do
    let(:command) { 'ls' }
    let(:response) { "foo\nbar" }

    before(:each) do
      expect(Zenflow::Shell).to receive(:run_with_result_check).with(command, {}).and_return(response)
      expect(Zenflow::Shell).to receive(:puts).with(Regexp.new(response))
    end

    subject { Zenflow::Shell.run_with_output(command) }
    it { expect(subject).to eq(response) }
  end

  describe '.run_without_output' do
    let(:command) { 'ls' }
    let(:response) { "foo\nbar" }

    before(:each) do
      expect(Zenflow::Shell).to receive(:run_with_result_check).with(command, {}).and_return(response)
    end

    subject { Zenflow::Shell.run_with_output(command) }
  end

  describe '.run_with_result_check' do
    context 'successful' do
      let(:command) { 'ls' }
      let(:response) { "foo\nbar" }

      before(:each) do
        expect(Zenflow::Shell).to receive(:`).with(command).and_return(response)
      end

      subject { Zenflow::Shell.run_with_result_check(command) }
      it { expect(subject).to eq(response) }
    end

    context 'unsuccessful' do
      let(:command) { 'ls' }
      let(:response) { '100' }

      before(:each) do
        allow(Zenflow::Shell).to receive(:last_exit_status).and_return(response)
        expect(Zenflow::Shell).to receive(:`).with(command).and_return(response)
        expect(Zenflow::Shell).to receive(:puts).with(Regexp.new(response))
        expect(Zenflow).to receive(:Log).with(/aborted/, color: :red)
        expect(Zenflow).to receive(:Log).with(/exit status: #{response}/i, color: :red, indent: true)
        expect(Zenflow).to receive(:Log).with(/following commands manually/, color: :red)
      end

      subject { Zenflow::Shell.run_with_result_check(command) }
      it { expect(subject).to eq(response) }
    end
  end
end
