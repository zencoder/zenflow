module Zenflow
  class Feature < BranchCommand

    flow "feature"

    branch :source => Zenflow::Config[:development_branch]
    branch :deploy => Zenflow::Config[:qa_branch]

  end
end
