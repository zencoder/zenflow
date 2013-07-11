module Zenflow
  module BranchCommands
    class Abort < BranchCommand

      desc "abort", "Aborts the branch and cleans up"
      option :offline, type: :boolean, desc: "Runs in offline mode"
      def abort
        delete_branches
      end

    end
  end
end
