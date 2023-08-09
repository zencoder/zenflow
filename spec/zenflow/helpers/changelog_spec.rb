require 'spec_helper'

describe Zenflow::Changelog do

  describe '.update' do
    context "when no changelog exists" do
      before { expect(File).to receive(:exist?).with("CHANGELOG.md").and_return(false) }
      it "does nothing" do
        expect(Zenflow::Changelog).to_not receive(:prompt_for_change)
        expect(Zenflow::Changelog.update).to be_nil
      end
    end

    context "when the changelog exists" do
      before { expect(File).to receive(:exist?).with("CHANGELOG.md").and_return(true) }

      context "when a change is received" do
        before { expect(Zenflow::Changelog).to receive(:prompt_for_change).and_return('wrote tests for updating the changelog') }

        it "prepends the change to the changelog and returns the change" do
          expect(Zenflow::Changelog).to receive(:prepend_change_to_changelog).with('* wrote tests for updating the changelog', {})
          expect(Zenflow::Changelog.update).to eq('wrote tests for updating the changelog')
        end
      end

      context "when no change is received" do
        before { expect(Zenflow::Changelog).to receive(:prompt_for_change).and_return(nil) }

        context "and the rotate option is invoked" do
          it "rotates the changelog and returns nil" do
            expect(Zenflow::Changelog).to receive(:rotate).with(:commit => true)
            expect(Zenflow::Changelog.update(:rotate => true)).to be_nil
          end
        end

        context "and the rotate option is absent" do
          it "rotates the changelog and returns nil" do
            expect(Zenflow::Changelog).to_not receive(:rotate)
            expect(Zenflow::Changelog.update).to be_nil
          end
        end
      end
    end
  end

  describe '.prompt_for_change' do
    context "when the required option is false" do
      it "asks for a change and indicates it is optional" do
        expect(Zenflow).to receive(:Ask).with("Add one line to the changelog (optional):", :required => false)
        Zenflow::Changelog.prompt_for_change(:required => false)
      end
    end

    context "when the required option is anything else" do
      it "asks for a change and does not indicate is optional" do
        expect(Zenflow).to receive(:Ask).with("Add one line to the changelog:", :required => true)
        Zenflow::Changelog.prompt_for_change
      end
    end
  end

  describe '.prepend_change_to_changelog' do
    context "when the rotate option is not invoked" do
      it "prepends changes to the changelog" do
        expect(Zenflow::Changelog).to receive(:prepended_changelog).with('changed the world').and_return('some other text I suppose')
        file_handler = double()
        expect(file_handler).to receive(:write).with('some other text I suppose')
        expect(File).to receive(:open).with("CHANGELOG.md", "w").and_yield(file_handler)
        expect(Zenflow::Changelog).to_not receive(:rotate)
        expect(Zenflow::Shell).to receive(:run).with("git add CHANGELOG.md && git commit -m 'Adding line to CHANGELOG: changed the world'")
        Zenflow::Changelog.prepend_change_to_changelog('changed the world')
      end
    end

    context "when the rotate option is present" do
      it "prepends changes to the changelog" do
        expect(File).to receive(:open).with("CHANGELOG.md", "w")
        expect(Zenflow::Changelog).to receive(:rotate)
        expect(Zenflow::Shell).to receive(:run).with("git add CHANGELOG.md && git commit -m 'Adding line to CHANGELOG: changed the world'")
        Zenflow::Changelog.prepend_change_to_changelog('changed the world', :rotate => true)
      end
    end
  end

  describe '.prepended_changelog' do
    it "returns the new changes prepended to the existing changelog" do
      expect(Zenflow::Changelog).to receive(:get_changes).and_return(['test branching', 'amongst other things'])
      expect(Zenflow::Changelog.prepended_changelog('test prepended changelog')).to eq("test prepended changelog\ntest branching\namongst other things\n")
    end
  end

  describe '.rotate' do
    context "when there are no changes to rotate" do
      before { expect(Zenflow::Changelog).to receive(:rotated_changelog).and_return(nil) }

      it "does nothing" do
        expect(File).to_not receive(:open)
        Zenflow::Changelog.rotate
      end
    end

    context "when there are no changes to rotate" do
      before { expect(Zenflow::Changelog).to receive(:rotated_changelog).and_return('amazing new changelog') }

      context "when the commit option is not invoked" do
        it "rotates the changelog but does not create a commit" do
          expect(Zenflow::Version).to receive(:current)
          expect(Zenflow).to receive(:Log)
          file_handler = double()
          expect(file_handler).to receive(:write).with('amazing new changelog')
          expect(File).to receive(:open).with("CHANGELOG.md", "w").and_yield(file_handler)
          expect(Zenflow::Shell).to_not receive(:run)
          Zenflow::Changelog.rotate
        end
      end

      context "when the commit option is present" do
        it "rotates the changelog and creates a commit" do
          expect(Zenflow::Version).to receive(:current)
          expect(Zenflow).to receive(:Log)
          file_handler = double()
          expect(file_handler).to receive(:write).with('amazing new changelog')
          expect(File).to receive(:open).with("CHANGELOG.md", "w").and_yield(file_handler)
          expect(Zenflow::Shell).to receive(:run).with("git add CHANGELOG.md && git commit -m 'Rotating CHANGELOG.'")
          Zenflow::Changelog.rotate(:commit => true)
        end
      end
    end
  end

  describe '.rotated_changelog' do
    it "returns the changelog with changes rotated to the bottom" do
      expect(Zenflow::Changelog).to receive(:get_changes).and_return(['test branching', 'amongst other things'])
      expect(Zenflow::Changelog.rotated_changelog).to match(/amongst other things\n\n---- #{Zenflow::Version.current.to_s} \/ #{Time.now.strftime('%Y-%m-%d')} [-]+\ntest branching\n/)
    end
  end

  describe '.get_changes' do
    context "when the changelog file doesn't exist" do
      before do
        expect(Zenflow::Changelog).to receive(:exist?).and_return(false)
      end

      it 'does nothing' do
        expect(File).to_not receive(:read)
        expect(Zenflow::Changelog.get_changes).to be_nil
      end
    end

    context "when the changelog exists" do
      before do
        expect(Zenflow::Changelog).to receive(:exist?).and_return(true)
      end

      context "but there are no changes" do
        before do
          @file = "\n--------------------------------------------------------------------------------\nold changes"
          expect(File).to receive(:read).with('CHANGELOG.md').and_return(@file)
        end

        it 'returns the no new changes, but include old changes' do
          expect(Zenflow::Changelog.get_changes).to eq(["", @file.strip])
        end
      end

      context "and there are changes" do
        before do
          file = "new changes\n--------------------------------------------------------------------------------\nold changes"
          expect(File).to receive(:read).with('CHANGELOG.md').and_return(file)
        end

        it "returns the new changes and the rest of the changelog" do
          expect(Zenflow::Changelog.get_changes).to eq(["new changes", "--------------------------------------------------------------------------------\nold changes"])
        end
      end
    end
  end

  describe '.create' do
    it "writes the changelog template to the changelog" do
      file = double()
      expect(file).to receive(:write).with(Zenflow::Changelog.changelog_template)
      expect(File).to receive(:open).with('CHANGELOG.md', 'w').and_yield(file)
      Zenflow::Changelog.create
    end
  end

end
