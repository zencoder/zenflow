module Zenflow
  module BranchCommands
    class Start < BranchCommand

      desc "start [NAME]", "Start a branch"
      option :offline, type: :boolean, desc: "Runs in offline mode"
      def start(name=nil)
        @branch_name = Zenflow::Ask("Name of the #{flow}:",
                                    required:      true,
                                    validate:      /^[-0-9a-z]+$/,
                                    error_message: "Names can only contain dashes, 0-9, and a-z",
                                    response:      name).downcase

        create_new_branch(options[:offline])
      end

      no_commands do
        def create_new_branch(offline=false)
          if !offline
            Zenflow::Branch.update(branch(:source))
            Zenflow::Branch.create("#{flow}/#{branch_name}", branch(:source))
            Zenflow::Branch.push("#{flow}/#{branch_name}")
            Zenflow::Branch.track("#{flow}/#{branch_name}")
          else
            Zenflow::Branch.checkout(branch(:source))
            Zenflow::Branch.create("#{flow}/#{branch_name}", branch(:source))
          end
        end
      end

    end
  end
end
