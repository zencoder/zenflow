require 'spec_helper'

describe Zenflow do
  describe "prompt" do
    before do
      allow(Zenflow).to receive(:LogToFile)
      allow($stdin).to receive(:gets).and_return("good")
    end

    it "displays a prompt" do
      expect(Zenflow::Requests::Query).to receive(:print).with(">> How are you? ")
      Zenflow::Requests.ask("How are you?")
    end

    it "displays a prompt with options" do
      expect(Zenflow::Requests::Query).to receive(:print).with(">> How are you? [good/bad] ")
      Zenflow::Requests.ask("How are you?", options: ["good", "bad"])
    end

    it "displays a prompt with default" do
      expect(Zenflow::Requests::Query).to receive(:print).with(">> How are you? [good] ")
      Zenflow::Requests.ask("How are you?", default: "good")
    end

    it "displays a prompt with options and default" do
      expect(Zenflow::Requests::Query).to receive(:print).with(">> How are you? [good/bad] ")
      Zenflow::Requests.ask("How are you?", options: ["good", "bad"], default: "good")
    end

    context "on error" do
      before(:each) do
        expect(Zenflow::Requests::Query).to receive(:ask_question).at_least(:once).and_return('foo')
        expect(Zenflow::Requests::Query).to receive(:handle_response).once.and_raise('something failed')
      end

      it 'should raise an error' do
        expect do
          Zenflow::Requests.ask('howdy', response: 'foo', error_message: 'something failed')
        end.to output(/something failed/).to_stdout.and raise_error(/something failed/)
      end
    end

    context "on interrupt" do
      before(:each) do
        expect(Zenflow::Requests::Query).to receive(:ask_question).once.and_return('foo')
        expect(Zenflow::Requests::Query).to receive(:handle_response).once.and_raise(Interrupt)
        expect(Zenflow).to receive(:LogToFile)
        expect($stdout).to receive(:puts).at_least(:once)
      end

      it { expect { Zenflow::Requests.ask('howdy') }.to raise_error(SystemExit) }
    end
  end

  describe Zenflow::Requests::Query do
    describe '.get_response' do
      context 'with a response' do
        it { expect(Zenflow::Requests::Query.ask_question('foo?', response: 'bar')).to eq('bar') }
      end

      context 'with a response' do
        before(:each) do
          expect(Zenflow::Requests::Query).to receive(:prompt_for_answer).with('foo?', {}).and_return('bar')
        end

        it { expect(Zenflow::Requests::Query.ask_question('foo?')).to eq('bar') }
      end
    end

    describe '.prompt_for_answer' do
      before(:each) do
        expect(Zenflow::Requests::Query).to receive(:print).with(">> Hi? [yes/bye] ")
        expect($stdin).to receive(:gets).and_return("bye")
      end

      it { expect(Zenflow::Requests::Query.prompt_for_answer('Hi?', options: ['yes', 'bye'])).to(eq('bye')) }
    end

    describe '.handle_response' do
      context 'invalid response' do
        before(:each) { expect(Zenflow::Requests::Query).to receive(:valid_response?).and_return(false) }
        it { expect { Zenflow::Requests::Query.handle_response('foo') }.to raise_error(/is not a valid response/)}
      end

      context 'valid response' do
        before(:each) { expect(Zenflow::Requests::Query).to receive(:valid_response?).and_return(true) }
        it { expect(Zenflow::Requests::Query.handle_response('foo')).to eq('foo') }
        it { expect(Zenflow::Requests::Query.handle_response('Y')).to eq('y') }
        it { expect(Zenflow::Requests::Query.handle_response('N')).to eq('n') }
        it { expect(Zenflow::Requests::Query.handle_response('', default: 'foo')).to eq('foo') }
        it { expect(Zenflow::Requests::Query.handle_response('', default: 'FOO')).to eq('foo') }
      end
    end

    describe '.valid_response?' do
      it { expect(Zenflow::Requests::Query.valid_response?('foo', options: ['foo'])).to eq(true) }
      it { expect(Zenflow::Requests::Query.valid_response?('foo', options: ['bar'])).to eq(false) }
      it { expect(Zenflow::Requests::Query.valid_response?('foo', validate: /foo/)).to eq(true) }
      it { expect(Zenflow::Requests::Query.valid_response?('foo', validate: /bar/)).to eq(false) }
      it { expect(Zenflow::Requests::Query.valid_response?('', required: true)).to eq(false) }
      it { expect(Zenflow::Requests::Query.valid_response?('foo', required: true)).to eq(true) }
      it { expect(Zenflow::Requests::Query.valid_response?('foo', required: false)).to eq(true) }
      it { expect(Zenflow::Requests::Query.valid_response?('', required: false)).to eq(true) }
      it { expect(Zenflow::Requests::Query.valid_response?('', default: 'MERGE', options: ['merge', 'rebase'])).to eq(true) }
      it { expect(Zenflow::Requests::Query.valid_response?('MERGE', options: ['merge', 'rebase'])).to eq(true) }
      it { expect(Zenflow::Requests::Query.valid_response?('rebase', options: ['MERGE', 'REBASE'])).to eq(true) }
    end

    describe '.build_error_message' do
      it { expect(Zenflow::Requests::Query.build_error_message('foo')).to match(/not a valid response/) }
      it { expect(Zenflow::Requests::Query.build_error_message('foo', error_message: 'stupid response.')).to match(/stupid response/) }
      it { expect(Zenflow::Requests::Query.build_error_message('foo', required: true)).to match(/must respond/) }
    end
  end
end
