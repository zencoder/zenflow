require 'spec_helper'

describe Zenflow::Help do

  describe "Zenflow.Help" do
    it "initializes and returns a new Zenflow::Help object" do
      expect(Zenflow.Help.class).to eq(Zenflow::Help.new.class)
    end
  end

  subject { Zenflow::Help.new(:command  => 'test-help',
                              :summary  => "tests Zenflow::Help",
                              :usage    => "test-help (optional please)",
                              :commands => ['test-help', 'spec-help'])}

  it{expect(subject.banner).to match(/Summary/)}
  it{expect(subject.banner).to match(/Usage/)}
  it{expect(subject.banner).to match(/Available Commands/)}
  it{expect(subject.banner).to match(/Options/)}

  context "#unknown_command" do
    describe "when the command is missing" do
      it "logs the error and exits" do
        expect(Zenflow).to receive(:Log).with "Missing command", :color => :red
        expect(lambda {Zenflow::Help.new.unknown_command}).to raise_error(SystemExit)
      end
    end

    describe "when the command is present" do
      it "logs the error and exits" do
        expect(Zenflow).to receive(:Log).with "Unknown command \"test-unknown_command\"", :color => :red
        expect(lambda {Zenflow::Help.new(:command => 'test-unknown_command').unknown_command}).to raise_error(SystemExit)
      end
    end
  end

end
