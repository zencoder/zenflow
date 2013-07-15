module Zenflow
  module BranchCommands
    module Abort

      def self.included(thor)
        thor.class_eval do

          desc "abort", "Aborts the branch and cleans up"
          option :offline, type: :boolean, desc: "Runs in offline mode"
          def abort
            delete_branches
          end

        end
      end

    end
  end
end
