module Zenflow
  module BranchCommands
    # Diff against the latest code
    module Diff
      def self.included(thor)
        thor.class_eval do
          desc "diff", "Launch a diff against the latest code"
          def diff
            Zenflow::Log("Displaying diff with #{branch(:source)}")
            Zenflow::Shell["git difftool #{branch(:source)}"]
          end
        end
      end
    end
  end
end
