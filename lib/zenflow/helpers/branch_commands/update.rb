module Zenflow
  module BranchCommands
    module Update

      def self.included(thor)
        thor.class_eval do

          desc "update", "Update the branch to the latest code"
          option :offline, type: :boolean, desc: "Runs in offline mode"
          option :rebase, type: :boolean, desc: "Rebases the current branch against a source branch instead of doing a merge of that source into itself"
          def update
            branch_name
            Zenflow::Branch.update(branch(:source), options[:rebase]) if !options[:offline]
            Zenflow::Branch.apply_merge_strategy(flow, branch_name, branch(:source), options[:rebase])
          end

        end
      end

    end
  end
end
