require 'spec_helper'

describe Zenflow do

  describe "prompt" do
    before do
      Zenflow.stub(:LogToFile)
      $stdin.stub(:gets).and_return("good")
    end

    it "displays a prompt" do
      Zenflow::Query.should_receive(:print).with(">> How are you? ")
      Zenflow::Ask("How are you?")
    end

    it "displays a prompt with options" do
      Zenflow::Query.should_receive(:print).with(">> How are you? [good/bad] ")
      Zenflow::Ask("How are you?", options: ["good", "bad"])
    end

    it "displays a prompt with default" do
      Zenflow::Query.should_receive(:print).with(">> How are you? [good] ")
      Zenflow::Ask("How are you?", default: "good")
    end

    it "displays a prompt with options and default" do
      Zenflow::Query.should_receive(:print).with(">> How are you? [good/bad] ")
      Zenflow::Ask("How are you?", options: ["good", "bad"], default: "good")
    end
  end

  describe Zenflow::Query do
    describe '.get_response' do
      context 'with a response' do
        it{expect(
          Zenflow::Query.ask_question('foo?', response: 'bar')).to eq('bar')
        }
      end

      context 'with a response' do
        before(:each) do
          Zenflow::Query.should_receive(:prompt_for_answer).with('foo?',{}).and_return('bar')
        end

        it{expect(Zenflow::Query.ask_question('foo?')).to eq('bar')}
      end
    end

    describe '.prompt_for_answer' do
      before(:each) do
        Zenflow::Query.should_receive(:print).with(">> Hi? [yes/bye] ")
        STDIN.should_receive(:gets).and_return("bye")
      end

      it{expect(
        Zenflow::Query.prompt_for_answer('Hi?', options: ['yes','bye'])
      ).to(
        eq('bye')
      ) }
    end

    describe '.handle_response' do
      context 'invalid response' do
        before(:each){Zenflow::Query.should_receive(:valid_response?).and_return(false)}
        it{expect{Zenflow::Query.handle_response('foo')}.to raise_error}
      end

      context 'valid response' do
        before(:each){Zenflow::Query.should_receive(:valid_response?).and_return(true)}
        it{expect(Zenflow::Query.handle_response('foo')).to eq('foo')}
        it{expect(Zenflow::Query.handle_response('Y')).to eq('y')}
        it{expect(Zenflow::Query.handle_response('N')).to eq('n')}
        it{expect(Zenflow::Query.handle_response('', default: 'foo')).to eq('foo')}
      end
    end

    describe '.valid_response?' do
      it{expect(Zenflow::Query.valid_response?('foo', options: ['foo'])).to eq(true)}
      it{expect(Zenflow::Query.valid_response?('foo', options: ['bar'])).to eq(false)}
      it{expect(Zenflow::Query.valid_response?('foo', validate: /foo/)).to eq(true)}
      it{expect(Zenflow::Query.valid_response?('foo', validate: /bar/)).to eq(false)}
      it{expect(Zenflow::Query.valid_response?('', required: true)).to eq(false)}
      it{expect(Zenflow::Query.valid_response?('foo', required: true)).to eq(true)}
      it{expect(Zenflow::Query.valid_response?('foo', required: false)).to eq(true)}
      it{expect(Zenflow::Query.valid_response?('', required: false)).to eq(true)}
    end

    describe '.build_error_message' do
      it{expect(Zenflow::Query.build_error_message('foo')).to match(/not a valid response/)}
      it{expect(Zenflow::Query.build_error_message('foo', error_message: 'stupid response.')).to match(/stupid response/)}
      it{expect(Zenflow::Query.build_error_message('foo', required: true)).to match(/must respond/)}
    end
  end
end
