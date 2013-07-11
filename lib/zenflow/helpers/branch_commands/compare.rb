module Zenflow
  module BranchCommands
    class Compare < BranchCommand

      desc "compare", "Launch GitHub compare view against the latest code"
      def compare
        branch_name
        Zenflow::Log("Opening GitHub compare view for #{branch(:source)}...#{flow}/#{branch_name}")
        Zenflow::Shell["open https://github.com/#{Zenflow::Repo.slug}/compare/#{branch(:source)}...#{flow}/#{branch_name}"]
      end
      

    end
  end
end
