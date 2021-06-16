module Zenflow
  module BranchCommands
    # Branch configurations when init
    module Start
      def self.included(thor)
        thor.class_eval do
          desc "start [NAME]", "Start a branch"
          option :offline, type: :boolean, desc: "Runs in offline mode"
          def start(name = nil)
            @branch_name = Zenflow::Requests.ask(
              "Name of the #{flow}:",
              required: true,
              validate: /^[-_0-9a-z]+$/,
              error_message: "Names can only contain dashes, underscores, 0-9, and a-z",
              response: name
            ).downcase

            create_new_branch(options[:offline])
          end

          no_commands do
            def create_new_branch(offline = false)
              if !offline
                Zenflow::Branch.update(branch(:source))
                Zenflow::Branch.create("#{flow}/#{branch_name}", branch(:source))
                unless Zenflow::Config[:merge_strategy] == 'rebase'
                  Zenflow::Branch.push("#{flow}/#{branch_name}")
                  Zenflow::Branch.track("#{flow}/#{branch_name}")
                end
              else
                Zenflow::Branch.checkout(branch(:source))
                Zenflow::Branch.create("#{flow}/#{branch_name}", branch(:source))
              end
            end
          end
        end
      end
    end
  end
end
