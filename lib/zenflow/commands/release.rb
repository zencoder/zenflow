module Zenflow
  class Release < BranchCommand

    flow "release"

    branch source: Zenflow::Config[:development_branch]
    branch deploy: Zenflow::Config[:staging_branch]
    branch deploy: Zenflow::Config[:qa_branch]
    branch destination: Zenflow::Config[:release_branch]

    changelog :rotate
    version :minor
    tag true

  end
end
