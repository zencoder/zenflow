require 'spec_helper'

describe Zenflow do

  describe "prompt" do
    before do
      Zenflow.stub(:LogToFile)
      $stdin.stub(:gets).and_return("good")
    end

    it "displays a prompt" do
      Zenflow.should_receive(:print).with(">> How are you? ")
      Zenflow::Ask("How are you?")
    end

    it "displays a prompt with options" do
      Zenflow.should_receive(:print).with(">> How are you? [good/bad] ")
      Zenflow::Ask("How are you?", options: ["good", "bad"])
    end

    it "displays a prompt with default" do
      Zenflow.should_receive(:print).with(">> How are you? [good] ")
      Zenflow::Ask("How are you?", default: "good")
    end

    it "displays a prompt with options and default" do
      Zenflow.should_receive(:print).with(">> How are you? [good/bad] ")
      Zenflow::Ask("How are you?", options: ["good", "bad"], default: "good")
    end
  end

end
