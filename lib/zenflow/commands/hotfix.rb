module Zenflow
  # Hotfix Flow
  class Hotfix < BranchCommand
    flow "hotfix"

    branch source:                Zenflow::Config[:release_branch]
    branch deploy:                Zenflow::Config[:staging_branch]
    branch deploy:                Zenflow::Config[:qa_branch]
    branch secondary_destination: Zenflow::Config[:development_branch]

    changelog :rotate
    version :patch
    tag true
  end
end
