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
            Zenflow::Branch.update(branch(:source)) if !options[:offline]
            if Zenflow::Config[:merge_strategy] == 'rebase' || options[:rebase]
              Zenflow::Branch.rebase("#{flow}/#{branch_name}", branch(:source))
            else
              Zenflow::Branch.checkout("#{flow}/#{branch_name}")
              Zenflow::Branch.merge(branch(:source))
            end
          end

        end
      end

    end
  end
end
