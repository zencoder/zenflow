require 'spec_helper'

describe Zenflow do
  describe 'Log' do
    context 'with indentation' do
      before(:each) do
        allow(Zenflow).to receive(:LogToFile)
      end

      it 'indents the text' do
        expect($stdout).to receive(:puts).with(/\s+foo/)
        Zenflow.Log('foo', indent: true)
      end

      it 'adds an arrow the text' do
        expect($stdout).to receive(:puts).with(/-----> foo/)
        Zenflow.Log('foo', arrows: true)
      end

      it 'colorizes the text' do
        expect($stdout).to receive(:puts).with(/foo/)
        Zenflow.Log('foo', color: :blue, arrows: false)
      end

      it 'does not colorize the text' do
        expect($stdout).to receive(:puts).with('foo')
        Zenflow.Log('foo', color: false, arrows: false)
      end
    end
  end
end
