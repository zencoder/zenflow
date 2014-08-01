module Zenflow
  class Bug < BranchCommand

    flow "bug"

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
