module Zenflow
  module BranchCommands
    class Deploy < BranchCommand

      desc "deploy [OPTIONS]", "Deploy"
      option :migrations, type: :boolean, desc: "Run migrations during deployment", aliases: :m
      def deploy
        branch_name
        if !Zenflow::Config[:deployable]
          Zenflow::Log("This project is not deployable right now", color: :red)
          exit(1)
        end
        all_branches(:deploy).each do |branch|
          Zenflow::Branch.update(branch)
          Zenflow::Branch.merge("#{flow}/#{branch_name}")
          Zenflow::Deploy(branch, options)
        end
        Zenflow::Branch.checkout("#{flow}/#{branch_name}")
      end

    end
  end
end
