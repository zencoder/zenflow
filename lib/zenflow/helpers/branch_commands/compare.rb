module Zenflow
  module BranchCommands
    # Code comparison with GitHub
    module Compare
      def self.included(thor)
        thor.class_eval do
          desc "compare", "Launch GitHub compare view against the latest code"
          def compare
            branch_name
            Zenflow::Log("Opening GitHub compare view for #{branch(:source)}...#{flow}/#{branch_name}")
            Zenflow::Shell["open https://github.com/#{Zenflow::Repo.slug}/compare/#{branch(:source)}...#{flow}/#{branch_name}"]
          end
        end
      end
    end
  end
end
