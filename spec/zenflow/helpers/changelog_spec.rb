require 'spec_helper'

describe Zenflow::Changelog do

  describe '.update' do
    context "when no changelog exists" do
      before { File.should_receive(:exist?).with("CHANGELOG.md").and_return(false) }
      it "does nothing" do
        Zenflow::Changelog.should_not_receive(:prompt_for_change)
        expect(Zenflow::Changelog.update).to be_nil
      end
    end

    context "when the changelog exists" do
      before { File.should_receive(:exist?).with("CHANGELOG.md").and_return(true) }

      context "when a change is received" do
        before { Zenflow::Changelog.should_receive(:prompt_for_change).and_return('wrote tests for updating the changelog') }

        it "prepends the change to the changelog and returns the change" do
          Zenflow::Changelog.should_receive(:prepend_change_to_changelog).with('wrote tests for updating the changelog', {})
          expect(Zenflow::Changelog.update).to eq('wrote tests for updating the changelog')
        end
      end

      context "when no change is received" do
        before { Zenflow::Changelog.should_receive(:prompt_for_change).and_return(nil) }

        context "and the rotate option is invoked" do
          it "rotates the changelog and returns nil" do
            Zenflow::Changelog.should_receive(:rotate).with(:commit => true)
            expect(Zenflow::Changelog.update(:rotate => true)).to be_nil
          end
        end

        context "and the rotate option is absent" do
          it "rotates the changelog and returns nil" do
            Zenflow::Changelog.should_not_receive(:rotate)
            expect(Zenflow::Changelog.update).to be_nil
          end
        end
      end
    end
  end

  describe '.prompt_for_change' do
    context "when the required option is false" do
      it "asks for a change and indicates it is optional" do
        Zenflow.should_receive(:Ask).with("Add one line to the changelog (optional):", :required => false)
        Zenflow::Changelog.prompt_for_change(:required => false)
      end
    end

    context "when the required option is anything else" do
      it "asks for a change and does not indicate is optional" do
        Zenflow.should_receive(:Ask).with("Add one line to the changelog:", :required => true)
        Zenflow::Changelog.prompt_for_change
      end
    end
  end

  describe '.prepend_change_to_changelog' do
    context "when the rotate option is not invoked" do
      it "prepends changes to the changelog" do
        Zenflow::Changelog.should_receive(:prepended_changelog).with('changed the world').and_return('some other text I suppose')
        file_handler = double()
        file_handler.should_receive(:write).with('some other text I suppose')
        File.should_receive(:open).with("CHANGELOG.md", "w").and_yield(file_handler)
        Zenflow::Changelog.should_not_receive(:rotate)
        Zenflow::Shell.should_receive(:run).with("git add . && git commit -a -m 'Adding line to CHANGELOG: changed the world'")
        Zenflow::Changelog.prepend_change_to_changelog('changed the world')
      end
    end

    context "when the rotate option is present" do
      it "prepends changes to the changelog" do
        File.should_receive(:open).with("CHANGELOG.md", "w")
        Zenflow::Changelog.should_receive(:rotate)
        Zenflow::Shell.should_receive(:run).with("git add . && git commit -a -m 'Adding line to CHANGELOG: changed the world'")
        Zenflow::Changelog.prepend_change_to_changelog('changed the world', :rotate => true)
      end
    end
  end

  describe '.prepended_changelog' do
    it "returns the new changes prepended to the existing changelog" do
      Zenflow::Changelog.should_receive(:get_changes).and_return(['test branching', 'amongst other things'])
      expect(Zenflow::Changelog.prepended_changelog('test prepended changelog')).to eq("test prepended changelog\ntest branching\n--------------------------------------------------------------------------------\namongst other things\n")
    end
  end

  describe '.rotate' do
    context "when there are no changes to rotate" do
      before { Zenflow::Changelog.should_receive(:rotated_changelog).and_return(nil) }

      it "does nothing" do
        File.should_not_receive(:open)
        Zenflow::Changelog.rotate
      end
    end

    context "when there are no changes to rotate" do
      before { Zenflow::Changelog.should_receive(:rotated_changelog).and_return('amazing new changelog') }

      context "when the commit option is not invoked" do
        it "rotates the changelog but does not create a commit" do
          Zenflow::Version.should_receive(:current)
          Zenflow.should_receive(:Log)
          file_handler = double()
          file_handler.should_receive(:write).with('amazing new changelog')
          File.should_receive(:open).with("CHANGELOG.md", "w").and_yield(file_handler)
          Zenflow::Shell.should_not_receive(:run)
          Zenflow::Changelog.rotate
        end
      end

      context "when the commit option is present" do
        it "rotates the changelog and creates a commit" do
          Zenflow::Version.should_receive(:current)
          Zenflow.should_receive(:Log)
          file_handler = double()
          file_handler.should_receive(:write).with('amazing new changelog')
          File.should_receive(:open).with("CHANGELOG.md", "w").and_yield(file_handler)
          Zenflow::Shell.should_receive(:run).with("git add CHANGELOG.md && git commit -a -m 'Rotating CHANGELOG.'")
          Zenflow::Changelog.rotate(:commit => true)
        end
      end
    end
  end

  describe '.rotated_changelog' do
    it "returns the changelog with changes rotated to the bottom" do
      Zenflow::Changelog.should_receive(:get_changes).and_return(['test branching', 'amongst other things'])
      expect(Zenflow::Changelog.rotated_changelog).to eq("amongst other things\n\n---- #{Zenflow::Version.current.to_s} / #{Time.now.strftime('%Y-%m-%d')} --------------------------------------------------------\ntest branching\n")
    end
  end

end
