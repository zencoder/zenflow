module Zenflow
  class Feature < BranchCommand

    flow "feature"

    branch source: Zenflow::Config[:development_branch]
    branch deploy: Zenflow::Config[:qa_branch]

    if Zenflow::Config[:release_branch]
      changelog :sans_rotation
    else
      changelog :rotate
      version :patch
    end

  end
end
