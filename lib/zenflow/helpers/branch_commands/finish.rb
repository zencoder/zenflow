module Zenflow
  module BranchCommands
    module Finish

      def self.included(thor)
        thor.class_eval do

          desc "finish", "Finish the branch and close the code review"
          option :offline, type: :boolean, desc: "Runs in offline mode"
          def finish
            branch_name
            confirm(:confirm_staging, "Has this been tested in a staging environment first?",
                                      "Sorry, deploy to a staging environment first")
            confirm(:confirm_review, "Has this been code reviewed yet?",
                                     "Please have someone look at this first")
            update_branch_from_destination
            update_version_and_changelog(version, changelog)
            merge_branch_into_destination
            create_tag
            delete_branches
          end

          no_commands do
            def confirm(confirmation, question, failure_response)
              return unless Zenflow::Config[confirmation]
              if Zenflow::Ask(question, options: ["Y", "n"], default: "y") == "n"
                Zenflow::Log(failure_response, color: :red)
                exit(1)
              end
            end

            def update_version_and_changelog(version, changelog)
              if version
                Zenflow::Version.update(version)
              end
              if changelog
                @change = Zenflow::Changelog.update(rotate: (changelog == :rotate), name: branch_name)
              end
            end

            def create_tag
              return unless tag
              Zenflow::Branch.tag(Zenflow::Version.current.to_s, @change)
              Zenflow::Branch.push_tags if !options[:offline]
            end

            def update_branch_from_destination
              destination = (branch(:destination) || branch(:source))
              Zenflow::Branch.update(destination) if !options[:offline]
              Zenflow::Branch.apply_merge_strategy(flow, branch_name, destination)
            end

            def merge_branch_into_destination
              [branch(:source), branch(:destination)].compact.each do |finish|
                Zenflow::Branch.checkout(finish)
                Zenflow::Branch.merge("#{flow}/#{branch_name}")
                Zenflow::Branch.push(finish) if !options[:offline]
              end
            end
          end

        end
      end

    end
  end
end
