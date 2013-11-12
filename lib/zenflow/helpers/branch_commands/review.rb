module Zenflow
  module BranchCommands
    module Review

      def self.included(thor)
        thor.class_eval do

          desc "review", "Start a code review."
          def review
            branch_name
            create_pull_request
          end

          no_commands do
            def create_pull_request
              already_created?(Zenflow::PullRequest.find_by_ref("#{flow}/#{branch_name}"))

              pull = Zenflow::PullRequest.create(
                :base =>  branch(:source),
                :head =>  "#{flow}/#{branch_name}",
                :title => "#{flow}: #{branch_name}",
                :body =>  Zenflow::Ask("Describe this #{flow}:", :required => true)
              )

              return handle_invalid_pull_request(pull) unless pull.valid?

              Zenflow::Log("Pull request was created!")
              Zenflow::Log(pull["html_url"], :indent => true, :color => false)
              Zenflow::Shell["open #{pull['html_url']}"]
            end

            def already_created?(pull)
              return unless pull
              Zenflow::Log("A pull request for #{flow}/#{branch_name} already exists", :color => :red)
              Zenflow::Log(pull[:html_url], :indent => true, :color => false)
              exit(1)
            end

            def handle_invalid_pull_request(pull)
              Zenflow::Log("There was a problem creating the pull request:", :color => :red)
              if pull["errors"]
                pull["errors"].each do |error|
                  Zenflow::Log("* #{error['message'].gsub(/^base\s*/,'')}", :indent => true, :color => :red)
                end
              elsif pull["message"]
                Zenflow::Log("* #{pull['message']}", :indent => true, :color => :red)
              else
                Zenflow::Log(" * unexpected failure, both 'errors' and 'message' were empty in the response")
              end
            end
          end

        end
      end

    end
  end
end
