module Zenflow
  module BranchCommands
    class Branches < BranchCommand

      desc "branches", "List branches"
      def branches
        Zenflow::Log("Available #{flow} branches:")
        Zenflow::Branch.list(flow).each do |branch|
          Zenflow::Log("* #{branch}", indent: true, color: false)
        end
      end

    end
  end
end
