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

  it "has an amazing banner" do
    expect(subject.banner).to eq("\e[36m- Summary ------------------------------\e[0m\ntests Zenflow::Help\n\n\e[36m- Usage --------------------------------\e[0m\ntest-help (optional please)\n\n\e[36m- Available Commands -------------------\e[0m\n[\"test-help\", \"spec-help\"]\n\n\e[36m- Options ------------------------------\e[0m")
  end

  context "#unknown_command" do
    describe "when the command is missing" do
      it "logs the error and exits" do
        Zenflow.should_receive(:Log).with "Missing command", :color => :red
        lambda {Zenflow::Help.new.unknown_command}.should raise_error(SystemExit)
      end
    end

    describe "when the command is present" do
      it "logs the error and exits" do
        Zenflow.should_receive(:Log).with "Unknown command \"test-unknown_command\"", :color => :red
        lambda {Zenflow::Help.new(:command => 'test-unknown_command').unknown_command}.should raise_error(SystemExit)
      end
    end
  end

end
