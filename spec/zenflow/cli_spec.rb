require 'spec_helper'

describe Zenflow::CLI do
  subject { Zenflow::CLI.new }

  describe "#version" do
    it 'outputs the version number' do
      expect(subject).to receive(:puts).with("Zenflow #{Zenflow::VERSION}")
      subject.version
    end
  end

  describe "#help" do
    it 'displays helpful information' do
      expect(subject).to receive(:version)
      expect($stdout).to receive(:puts).at_least(:once)
      subject.help
    end
  end

  describe "#already_configured" do
    let(:question) do
      ['There is an existing config file. Overwrite it?', { options: ["y", "N"], default: "n" }]
    end
    before do
      expect(Zenflow).to receive(:Log).with('Warning', color: :red)
    end

    context "when the user wants to overwrite the configuration" do
      before do
        expect(Zenflow::Requests).to receive(:ask).with(*question).and_return('y')
      end

      it "forces initialization" do
        expect(subject).to receive(:init).with(true)
        subject.already_configured
      end
    end

    context "when the user does not want to overwrite the configuration" do
      before do
        expect(Zenflow::Requests).to receive(:ask).with(*question).and_return('n')
      end

      it "aborts" do
        expect(Zenflow).to receive(:Log).with('Aborting...', color: :red)
        expect{ subject.already_configured }.to raise_error(SystemExit)
      end
    end
  end

  describe "#configure_branch" do
    context "when the user wants to configure a staging branch" do
      before do
        expect(Zenflow::Requests).to receive(:ask).with(
          "Use a branch for staging releases and hotfixes?",
          options: ["Y", "n"],
          default: "y"
        ).and_return('y')
      end

      it 'names the staging branch whatever the user wants' do
        expect(Zenflow::Requests).to receive(:ask).with(
          "What is the name of that branch?",
          default: "staging"
        ).and_return('staging')
        expect(Zenflow::Config).to receive(:[]=).with(:staging_branch, 'staging')
        subject.configure_branch(
          :staging_branch,
          "Use a branch for staging releases and hotfixes?",
          'staging'
        )
      end
    end

    context "when the user does not want to configure a staging branch" do
      before do
        expect(Zenflow::Requests).to receive(:ask).with(
          "Use a branch for staging releases and hotfixes?",
          options: ["Y", "n"],
          default: "y"
        ).and_return('n')
      end

      it 'names the staging branch whatever the user wants' do
        expect(Zenflow::Config).to receive(:[]=).with(:staging_branch, false)
        subject.configure_branch(
          :staging_branch,
          "Use a branch for staging releases and hotfixes?",
          'staging'
        )
      end
    end
  end

  describe "#configure_merge_strategy" do
    context "when the user wants to keep the default merge strategy of 'merge'" do
      it 'sets the merge strategy to merge' do
        expect(Zenflow::Requests).to receive(:ask).with(
          "What merge strategy would you prefer?",
          options: ["merge", "rebase"],
          default: "merge"
        ).and_return('merge')
        expect(Zenflow::Config).to receive(:[]=).with(:merge_strategy, 'merge')
        subject.configure_merge_strategy
      end
    end

    context "when the user wants to change the default merge strategy to 'rebase'" do
      it 'sets the merge strategy to rebase' do
        expect(Zenflow::Requests).to receive(:ask).with(
          "What merge strategy would you prefer?",
          options: ["merge", "rebase"],
          default: "merge"
        ).and_return('rebase')
        expect(Zenflow::Config).to receive(:[]=).with(:merge_strategy, 'rebase')
        subject.configure_merge_strategy
      end
    end
  end

  describe "#configure_project" do
    it 'asks the user to name their project' do
      expect(Zenflow::Requests).to receive(:ask).with(
        "What is the name of this project?",
        required: true
      ).and_return('zenflow')
      expect(Zenflow).to receive(:Log).with("Project")
      expect(Zenflow::Config).to receive(:[]=).with(:project, 'zenflow')
      subject.configure_project
    end
  end

  describe "#configure_branches" do
    it 'configures branches for the project' do
      expect(Zenflow::Requests).to receive(:ask).with(
        "What is the name of the main development branch?",
        default: "master"
      ).and_return('master')
      expect(Zenflow).to receive(:Log).with("Branches")
      expect(Zenflow::Config).to receive(:[]=).with(:development_branch, 'master')
      expect(subject).to receive(:configure_branch).exactly(3).times
      subject.configure_branches
    end
  end

  describe "#configure_remotes" do
    context "when the user wants to configure a backup remote" do
      before do
        expect(Zenflow::Requests).to receive(:ask).with(
          "Use a backup remote?",
          options: ["y", "N"],
          default: "n"
        ).and_return('y')
      end

      it 'configures the primary remote and a backup remote' do
        expect(Zenflow::Requests).to receive(:ask).with(
          "What is the name of your primary remote?",
          default: "origin"
        ).and_return('origin')
        expect(Zenflow::Config).to receive(:[]=).with(:remote, 'origin')
        expect(Zenflow::Requests).to receive(:ask).with(
          "What is the name of your backup remote?",
          default: "backup"
        ).and_return('backup')
        expect(Zenflow::Config).to receive(:[]=).with(:backup_remote, 'backup')
        subject.configure_remotes
      end
    end

    context "when the user does not want to configure a backup remote" do
      before do
        expect(Zenflow::Requests).to receive(:ask).with(
          "Use a backup remote?",
          options: ["y", "N"],
          default: "n"
        ).and_return('n')
      end

      it 'configures the primary remote and a backup remote' do
        expect(Zenflow::Requests).to receive(:ask).with(
          "What is the name of your primary remote?",
          default: "origin"
        ).and_return('origin')
        expect(Zenflow::Config).to receive(:[]=).with(:remote, 'origin')
        expect(Zenflow::Requests).to_not receive(:ask).with(
          "What is the name of your backup remote?",
          default: "backup"
        )
        expect(Zenflow::Config).to receive(:[]=).with(:backup_remote, false)
        subject.configure_remotes
      end
    end
  end

  describe "#set_up_changelog" do
    context "when the changelog doesn't already exist" do
      before do
        expect(File).to receive(:exist?).with("CHANGELOG.md").and_return(false)
        expect(Zenflow).to receive(:Log).with("Changelog Management")
      end

      context "when the user wants to set up a changelog" do
        it 'sets up the changelog' do
          expect(Zenflow::Requests).to receive(:ask).with(
            "Set up a changelog?",
            options: ["Y", "n"],
            default: "y"
          ).and_return('y')
          expect(Zenflow::Changelog).to receive(:create)
          subject.set_up_changelog
        end
      end

      context "when the user does not want to set up a changelog" do
        it 'does not set up the changelog' do
          expect(Zenflow::Requests).to receive(:ask).with(
            "Set up a changelog?",
            options: ["Y", "n"],
            default: "y"
          ).and_return('n')
          expect(Zenflow::Changelog).to_not receive(:create)
          subject.set_up_changelog
        end
      end
    end

    context "when the changelog already exists" do
      before do
        expect(File).to receive(:exist?).with("CHANGELOG.md").and_return(true)
      end

      it 'does not set up the changelog' do
        expect(Zenflow).to_not receive(:Log).with("Changelog Management")
        expect(Zenflow::Requests).to_not receive(:ask).with(
          "Set up a changelog?",
          options: ["Y", "n"],
          default: "y"
        )
        expect(Zenflow::Changelog).to_not receive(:create)
        subject.set_up_changelog
      end
    end
  end

  describe "#confirm_some_stuff" do
    it "confirms staging deployment and code review requirements" do
      expect(Zenflow).to receive(:Log).with("Confirmations")
      expect(Zenflow::Requests).to receive(:ask).with(
        "Require deployment to a staging environment?",
        options: ["Y", "n"],
        default: "y"
      ).and_return('y')
      expect(Zenflow::Config).to receive(:[]=).with(:confirm_staging, true)
      expect(Zenflow::Requests).to receive(:ask).with(
        "Require code reviews?",
        options: ["Y", "n"],
        default: "y"
      ).and_return('n')
      expect(Zenflow::Config).to receive(:[]=).with(:confirm_review, false)
      subject.confirm_some_stuff
    end
  end

  describe "#init" do
    let(:current) { Zenflow::Github.new('current') }

    before do
      stub_const("Zenflow::Github::CURRENT", current)
    end

    context "when in a project that doesn't belong to the default hub" do
      before do
        expect(current).to receive(:default_hub?).and_return(false)
      end

      context "when zenflow has not been configured" do
        before do
          expect(Zenflow::Config).to receive(:configured?).and_return(false)
        end

        it 'configures zenflow' do
          expect(subject).to_not receive(:already_configured)
          expect(current).to receive(:config)
          expect(current).to receive(:authorize)
          expect(subject).to receive(:configure_project)
          expect(subject).to receive(:configure_branches)
          expect(subject).to receive(:configure_merge_strategy)
          expect(subject).to receive(:configure_remotes)
          expect(subject).to receive(:confirm_some_stuff)
          expect(subject).to receive(:set_up_changelog)
          expect(Zenflow::Config).to receive(:save!)
          subject.init
        end
      end
    end

    context "when zenflow has not been configured" do
      before do
        expect(Zenflow::Config).to receive(:configured?).and_return(false)
        expect(current).to receive(:default_hub?).and_return(true)
      end

      it 'configures zenflow' do
        expect(subject).to_not receive(:already_configured)
        expect(current).to receive(:set_user)
        expect(current).to receive(:authorize)
        expect(subject).to receive(:configure_project)
        expect(subject).to receive(:configure_branches)
        expect(subject).to receive(:configure_merge_strategy)
        expect(subject).to receive(:configure_remotes)
        expect(subject).to receive(:confirm_some_stuff)
        expect(subject).to receive(:set_up_changelog)
        expect(Zenflow::Config).to receive(:save!)
        subject.init
      end
    end

    context "when zenflow has already been configured" do
      before do
        expect(Zenflow::Config).to receive(:configured?).and_return(true)
      end

      context 'and it is forced to initialize' do
        before do
          expect(current).to receive(:default_hub?).and_return(true)
        end

        it 'configures zenflow' do
          expect(subject).to_not receive(:already_configured)
          expect(current).to receive(:set_user)
          expect(current).to receive(:authorize)
          expect(subject).to receive(:configure_project)
          expect(subject).to receive(:configure_branches)
          expect(subject).to receive(:configure_merge_strategy)
          expect(subject).to receive(:configure_remotes)
          expect(subject).to receive(:confirm_some_stuff)
          expect(subject).to receive(:set_up_changelog)
          expect(Zenflow::Config).to receive(:save!)
          subject.init(force: true)
        end
      end

      context 'and it is forced to initialize' do
        before do
          expect(Zenflow).to receive(:Log).with('Warning', color: :red)
          expect(Zenflow::Requests).to receive(:ask).and_return('n')
          expect(Zenflow).to receive(:Log).with('Aborting...', color: :red)
        end

        it 'calls already_configured' do
          expect(subject).to receive(:already_configured).and_call_original
          expect(current).to_not receive(:set_user)
          expect(current).to_not receive(:authorize)
          expect(subject).to_not receive(:configure_branches)
          expect(subject).to_not receive(:configure_merge_strategy)
          expect(subject).to_not receive(:configure_remotes)
          expect(subject).to_not receive(:confirm_some_stuff)
          expect(subject).to_not receive(:set_up_changelog)
          expect(Zenflow::Config).to_not receive(:save!)
          expect{ subject.init }.to raise_error(SystemExit)
        end
      end
    end
  end
end

