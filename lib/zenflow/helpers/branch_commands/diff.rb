module Zenflow
  module BranchCommands
    class Diff < BranchCommand

      desc "diff", "Launch a diff against the latest code"
      def diff
        Zenflow::Log("Displaying diff with #{branch(:source)}")
        Zenflow::Shell["git difftool #{branch(:source)}"]
      end

    end
  end
end
