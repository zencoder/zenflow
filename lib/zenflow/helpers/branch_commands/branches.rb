module Zenflow
  module BranchCommands
    module Branches

      def self.included(thor)
        thor.class_eval do

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
  end
end
