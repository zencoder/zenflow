require 'spec_helper'

module BranchCommandSpecs
  module Start

    class TestCommand < Zenflow::BranchCommands::Start
      flow "test"
      branch source: "master"
      branch destination: "production"
      branch deploy: "deploy1"
      branch deploy: "deploy2"
      version :patch
      changelog :rotate
      tag true
    end

    describe "Zenflow::BranchCommands::Start" do

      context "when online" do
        before do
          Zenflow.should_receive(:Ask).and_return("new-test-branch")
          Zenflow::Branch.should_receive(:update).with("master")
          Zenflow::Branch.should_receive(:create).with("test/new-test-branch", "master")
          Zenflow::Branch.should_receive(:push).with("test/new-test-branch")
          Zenflow::Branch.should_receive(:track).with("test/new-test-branch")
        end
        it { TestCommand.new.invoke(:start) }
      end

      context "when offline" do
        before do
          Zenflow.should_receive(:Ask).and_return("new-test-branch")
          Zenflow::Branch.should_receive(:checkout).with("master")
          Zenflow::Branch.should_receive(:create).with("test/new-test-branch", "master")
        end
        it { TestCommand.new.invoke(:start, nil, offline: true) }
      end

      context "when supplying a name" do
        before do
          Zenflow::Branch.should_receive(:update).with("master")
          Zenflow::Branch.should_receive(:create).with("test/new-test-branch", "master")
          Zenflow::Branch.should_receive(:push).with("test/new-test-branch")
          Zenflow::Branch.should_receive(:track).with("test/new-test-branch")
        end
        it { TestCommand.new.invoke(:start, ["new-test-branch"]) }
      end

      context "when asking for a name" do
        before do
          $stdin.should_receive(:gets).and_return("new-test-branch\n")
          Zenflow::Branch.should_receive(:update).with("master")
          Zenflow::Branch.should_receive(:create).with("test/new-test-branch", "master")
          Zenflow::Branch.should_receive(:push).with("test/new-test-branch")
          Zenflow::Branch.should_receive(:track).with("test/new-test-branch")
        end
        it { expect(capture(:stdout){ TestCommand.new.invoke(:start) }).to eq(">> Name of the test: ") }
      end

    end

  end
end
