require 'spec_helper'

describe Zenflow::Branch do
  describe 'self.list' do
    context "when the prefix has no branches" do
      before do
        expect(Zenflow::Shell).to receive(:run).with(
          "git branch | grep features", silent: true
        ).and_return("")
      end

      it "indicates there are no branches" do
        expect(Zenflow::Branch.list('features')).to eq(['!! NONE !!'])
      end
    end

    context "when the prefix has branches" do
      before do
        expect(Zenflow::Shell).to receive(:run).with(
          "git branch | grep features",
          silent: true
        ).and_return("  feature/test_zenflow\n* feature/refactor_zenflow\n")
      end

      it "indicates there are no branches" do
        expect(Zenflow::Branch.list('features')).to(
          eq(["  feature/test_zenflow", "* feature/refactor_zenflow"])
        )
      end
    end
  end

  describe "self.current" do
    context "when the current branch doesn't match the prefix" do
      before do
        expect(Zenflow::Shell).to receive(:run).with(
          "git branch | grep '* feature'", silent: true
        ).and_return("")
      end

      it "returns nil" do
        expect(Zenflow::Branch.current('feature')).to be_nil
      end
    end

    context "when the current branch matches the prefix" do
      before do
        expect(Zenflow::Shell).to receive(:run).with(
          "git branch | grep '* feature'",
          silent: true
        ).and_return("* feature/test-current-branch\n")
      end

      it "returns returns the branch name" do
        expect(Zenflow::Branch.current('feature')).to eq('test-current-branch')
      end
    end
  end

  describe "self.update" do
    it "updates the branch" do
      expect(Zenflow::Config).to receive(:[]).with(:merge_strategy).and_return('merge')
      expect(Zenflow).to receive(:Log).with("Updating the master branch")
      expect(Zenflow::Shell).to receive(:run).with("git checkout master && git pull")
      Zenflow::Branch.update('master')
    end

    it "updates the branch using a rebase override" do
      expect(Zenflow::Config).to receive(:[]).with(:merge_strategy).and_return('merge')
      expect(Zenflow).to receive(:Log).with("Updating the master branch using pull with --rebase")
      expect(Zenflow::Shell).to receive(:run).with("git checkout master && git pull --rebase")
      Zenflow::Branch.update('master', true)
    end
  end

  describe "self.apply_merge_strategy" do
    it "merges the branch using the merge strategy" do
      expect(Zenflow::Config).to receive(:[]).with(:merge_strategy).and_return('merge')
      expect(Zenflow::Branch).to receive(:checkout).with("feature/testing-123")
      expect(Zenflow::Branch).to receive(:merge).with('master')

      Zenflow::Branch.apply_merge_strategy('feature', 'testing-123', 'master')
    end

    it "merges the branch using the rebase strategy" do
      expect(Zenflow::Config).to receive(:[]).with(:merge_strategy).and_return('rebase')
      expect(Zenflow::Branch).to receive(:rebase).with("feature/testing-123", 'master')

      Zenflow::Branch.apply_merge_strategy('feature', 'testing-123', 'master')
    end

    it "optionally allows the merge strategy to be overridden by a --rebase flag when doing an update" do
      expect(Zenflow::Config).to receive(:[]).with(:merge_strategy).and_return('merge')
      expect(Zenflow::Branch).to receive(:rebase).with("feature/testing-123", 'master')

      Zenflow::Branch.apply_merge_strategy('feature', 'testing-123', 'master', true)
    end
  end

  describe "self.create" do
    it "updates the branch" do
      expect(Zenflow).to receive(:Log).with(
        "Creating the feature/test-branch-creation branch based on master"
      )
      expect(Zenflow::Shell).to receive(:run).with("git checkout -b feature/test-branch-creation master")
      Zenflow::Branch.create('feature/test-branch-creation', 'master')
    end
  end

  describe "self.push" do
    after(:each) do
      Zenflow::Config[:remote] = 'origin'
      Zenflow::Config[:backup_remote] = false
    end

    context "when a remote is configured" do
      before do
        Zenflow::Config[:remote] = 'some-remote'
      end

      it 'pushes to the configured remote' do
        expect(Zenflow).to receive(:Log).with("Pushing the feature/test-pushing branch to some-remote")
        expect(Zenflow::Shell).to receive(:run).with("git push some-remote feature/test-pushing")
        Zenflow::Branch.push('feature/test-pushing')
      end
    end

    context "when a remote is not configured" do
      it 'pushes to the origin' do
        expect(Zenflow).to receive(:Log).with("Pushing the feature/test-pushing branch to origin")
        expect(Zenflow::Shell).to receive(:run).with("git push origin feature/test-pushing")
        Zenflow::Branch.push('feature/test-pushing')
      end
    end

    context "when a backup remote is not configured" do
      it "pushes to the primary remote and then pushes to the backup remote" do
        expect(Zenflow).to receive(:Log).with("Pushing the feature/test-pushing branch to origin")
        expect(Zenflow::Shell).to receive(:run).with("git push origin feature/test-pushing")
        expect(Zenflow).to_not receive(:Log).with("Pushing the feature/test-pushing branch to backup-remote")
        expect(Zenflow::Shell).to_not receive(:run).with("git push backup-remote feature/test-pushing")
        Zenflow::Branch.push('feature/test-pushing')
      end
    end

    context "when a backup remote is configured" do
      before do
        Zenflow::Config[:backup_remote] = 'backup-remote'
      end

      it "pushes to the primary remote and then pushes to the backup remote" do
        expect(Zenflow).to receive(:Log).with("Pushing the feature/test-pushing branch to origin")
        expect(Zenflow::Shell).to receive(:run).with("git push origin feature/test-pushing")
        expect(Zenflow).to receive(:Log).with("Pushing the feature/test-pushing branch to backup-remote")
        expect(Zenflow::Shell).to receive(:run).with("git push backup-remote feature/test-pushing")
        Zenflow::Branch.push('feature/test-pushing')
      end
    end
  end

  describe "self.push_tags" do
    after(:each) do
      Zenflow::Config[:remote] = 'origin'
      Zenflow::Config[:backup_remote] = false
    end

    context "when a remote is configured" do
      before do
        Zenflow::Config[:remote] = 'some-remote'
      end

      it 'pushes to the configured remote' do
        expect(Zenflow).to receive(:Log).with("Pushing tags to some-remote")
        expect(Zenflow::Shell).to receive(:run).with("git push some-remote --tags")
        Zenflow::Branch.push_tags
      end
    end

    context "when a remote is not configured" do
      it 'pushes to the origin' do
        expect(Zenflow).to receive(:Log).with("Pushing tags to origin")
        expect(Zenflow::Shell).to receive(:run).with("git push origin --tags")
        Zenflow::Branch.push_tags
      end
    end

    context "when a backup remote is not configured" do
      it "pushes to the primary remote and then pushes to the backup remote" do
        expect(Zenflow).to receive(:Log).with("Pushing tags to origin")
        expect(Zenflow::Shell).to receive(:run).with("git push origin --tags")
        expect(Zenflow).to_not receive(:Log).with("Pushing tags to backup-remote")
        expect(Zenflow::Shell).to_not receive(:run).with("git push backup-remote --tags")
        Zenflow::Branch.push_tags
      end
    end

    context "when a backup remote is configured" do
      before do
        Zenflow::Config[:backup_remote] = 'backup-remote'
      end

      it "pushes to the primary remote and then pushes to the backup remote" do
        expect(Zenflow).to receive(:Log).with("Pushing tags to origin")
        expect(Zenflow::Shell).to receive(:run).with("git push origin --tags")
        expect(Zenflow).to receive(:Log).with("Pushing tags to backup-remote")
        expect(Zenflow::Shell).to receive(:run).with("git push backup-remote --tags")
        Zenflow::Branch.push_tags
      end
    end
  end

  describe "self.track" do
    after(:each) do
      Zenflow::Config[:remote] = 'origin'
    end

    context "when a remote is configured" do
      before do
        Zenflow::Config[:remote] = 'some-remote'
      end

      it "tracks the branch in that remote" do
        expect(Zenflow).to receive(:Log).with(
          "Tracking the feature/test-tracking branch against some-remote/feature/test-tracking"
        )
        expect(Zenflow::Shell).to receive(:run).with(
          "git branch --set-upstream-to=some-remote/feature/test-tracking feature/test-tracking"
        )
        Zenflow::Branch.track('feature/test-tracking')
      end
    end

    context "when a remote is not configured" do
      before do
        Zenflow::Config[:remote] = nil
      end

      it "tracks the branch in origin" do
        expect(Zenflow).to receive(:Log).with(
          "Tracking the feature/test-tracking branch against origin/feature/test-tracking"
        )
        expect(Zenflow::Shell).to receive(:run).with(
          "git branch --set-upstream-to=origin/feature/test-tracking feature/test-tracking"
        )
        Zenflow::Branch.track('feature/test-tracking')
      end
    end
  end

  describe "self.checkout" do
    it "checks out the branch" do
      expect(Zenflow).to receive(:Log).with("Switching to the feature/test-checkout branch")
      expect(Zenflow::Shell).to receive(:run).with("git checkout feature/test-checkout")
      Zenflow::Branch.checkout('feature/test-checkout')
    end
  end

  describe "self.rebase" do
    it "checks out the branch" do
      expect(Zenflow).to receive(:Log).with("Rebasing feature/test-checkout on top of the master branch")
      expect(Zenflow::Shell).to receive(:run).with("git rebase master feature/test-checkout")
      Zenflow::Branch.rebase('feature/test-checkout', 'master')
    end
  end

  describe "self.merge" do
    it "merges in the specified branch" do
      expect(Zenflow).to receive(:Log).with("Merging in the feature/test-merging branch")
      expect(Zenflow::Shell).to receive(:run).with("git merge --no-ff feature/test-merging")
      Zenflow::Branch.merge('feature/test-merging')
    end
  end

  describe "self.tag" do
    context "when name and description are specified" do
      it "creates a tag with the name and description" do
        expect(Zenflow).to receive(:Log).with("Tagging the release")
        expect(Zenflow::Shell).to receive(:run).with("git tag -a 'v0.1.2' -m 'this tag is amazing'")
        Zenflow::Branch.tag('v0.1.2', 'this tag is amazing')
      end
    end

    context "when name and description are not specified" do
      it "asks for name and description and then creates a tag" do
        expect(Zenflow).to receive(:Log).with("Tagging the release")
        expect(Zenflow::Requests).to receive(:ask).with(
          'Name of the tag:', required: true
        ).and_return('v0.1.3')
        expect(Zenflow::Requests).to receive(:ask).with(
          'Tag message:',
          required: true
        ).and_return('this tag is even more amazing')
        expect(Zenflow::Shell).to receive(:run).with("git tag -a 'v0.1.3' -m 'this tag is even more amazing'")
        Zenflow::Branch.tag
      end
    end
  end

  describe "self.delete_remote" do
    after(:each) do
      Zenflow::Config[:remote] = 'origin'
      Zenflow::Config[:backup_remote] = false
    end

    context "when a remote is configured" do
      before do
        Zenflow::Config[:remote] = 'some-remote'
      end

      it 'pushes to the configured remote' do
        expect(Zenflow).to receive(:Log).with("Removing the remote branch from some-remote")
        expect(Zenflow::Shell).to receive(:run).with(
          "git branch -r | grep some-remote/feature/test-remote-removal && git push some-remote :feature/test-remote-removal || echo ''"
        )
        Zenflow::Branch.delete_remote('feature/test-remote-removal')
      end
    end

    context "when a remote is not configured" do
      it 'pushes to the origin' do
        expect(Zenflow).to receive(:Log).with("Removing the remote branch from origin")
        expect(Zenflow::Shell).to receive(:run).with(
          "git branch -r | grep origin/feature/test-remote-removal && git push origin :feature/test-remote-removal || echo ''"
        )
        Zenflow::Branch.delete_remote('feature/test-remote-removal')
      end
    end

    context "when a backup remote is not configured" do
      it "pushes to the primary remote and then pushes to the backup remote" do
        expect(Zenflow).to receive(:Log).with("Removing the remote branch from origin")
        expect(Zenflow::Shell).to receive(:run).with(
          "git branch -r | grep origin/feature/test-remote-removal && git push origin :feature/test-remote-removal || echo ''"
        )
        expect(Zenflow).to_not receive(:Log).with(/Removing the remote branch/)
        expect(Zenflow::Shell).to_not receive(:run).with(/git push/)
        Zenflow::Branch.delete_remote('feature/test-remote-removal')
      end
    end

    context "when a backup remote is configured" do
      before do
        Zenflow::Config[:backup_remote] = 'backup-remote'
      end

      it "pushes to the primary remote and then pushes to the backup remote" do
        expect(Zenflow).to receive(:Log).with("Removing the remote branch from origin")
        expect(Zenflow::Shell).to receive(:run).with(
          "git branch -r | grep origin/feature/test-remote-removal && git push origin :feature/test-remote-removal || echo ''"
        )
        expect(Zenflow).to receive(:Log).with("Removing the remote branch from backup-remote")
        expect(Zenflow::Shell).to receive(:run).with(
          "git branch -r | grep backup-remote/feature/test-remote-removal && git push backup-remote :feature/test-remote-removal || echo ''"
        )
        Zenflow::Branch.delete_remote('feature/test-remote-removal')
      end
    end
  end

  describe "self.delete_local" do
    context "with the force option" do
      it "force deletes the local branch" do
        expect(Zenflow).to receive(:Log).with("Removing the local branch")
        expect(Zenflow::Shell).to receive(:run).with("git branch -D feature/test-local-deletion")
        Zenflow::Branch.delete_local('feature/test-local-deletion', force: true)
      end
    end

    context "without the force option" do
      it "deletes the local branch" do
        expect(Zenflow).to receive(:Log).with("Removing the local branch")
        expect(Zenflow::Shell).to receive(:run).with("git branch -d feature/test-local-deletion")
        Zenflow::Branch.delete_local('feature/test-local-deletion')
      end
    end
  end
end
