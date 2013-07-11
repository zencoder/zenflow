module Zenflow
  class BranchCommand < Thor

    desc "branches", "List branches"
    def branches
      Zenflow::Log("Available #{flow} branches:")
      Zenflow::Branch.list(flow).each do |branch|
        Zenflow::Log("* #{branch}", indent: true, color: false)
      end
    end

    desc "start [NAME]", "Start a branch"
    option :offline, type: :boolean, desc: "Runs in offline mode"
    def start(name=nil)
      @branch_name = Zenflow::Ask("Name of the #{flow}:",
                                  required:      true,
                                  validate:      /^[-0-9a-z]+$/,
                                  error_message: "Names can only contain dashes, 0-9, and a-z",
                                  response:      name).downcase
      if !options[:offline]
        Zenflow::Branch.update(branch(:source))
      else
        Zenflow::Branch.checkout(branch(:source))
      end
      Zenflow::Branch.create("#{flow}/#{branch_name}", branch(:source))
      if !options[:offline]
        Zenflow::Branch.push("#{flow}/#{branch_name}")
        Zenflow::Branch.track("#{flow}/#{branch_name}")
      end
    end

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

    desc "update", "Update the branch to the latest code"
    option :offline, type: :boolean, desc: "Runs in offline mode"
    def update
      branch_name
      Zenflow::Branch.update(branch(:source)) if !options[:offline]
      Zenflow::Branch.checkout("#{flow}/#{branch_name}")
      Zenflow::Branch.merge(branch(:source))
    end

    desc "diff", "Launch a diff against the latest code"
    def diff
      Zenflow::Log("Displaying diff with #{branch(:source)}")
      Zenflow::Shell["git difftool #{branch(:source)}"]
    end

    desc "compare", "Launch GitHub compare view against the latest code"
    def compare
      branch_name
      Zenflow::Log("Opening GitHub compare view for #{branch(:source)}...#{flow}/#{branch_name}")
      Zenflow::Shell["open https://github.com/#{Zenflow::Repo.slug}/compare/#{branch(:source)}...#{flow}/#{branch_name}"]
    end

    desc "review", "Start a code review."
    def review
      branch_name
      create_pull_request
    end

    desc "abort", "Aborts the branch and cleans up"
    option :offline, type: :boolean, desc: "Runs in offline mode"
    def abort
      Zenflow::Branch.delete_remote("#{flow}/#{branch_name}") if !options[:offline]
      Zenflow::Branch.delete_local("#{flow}/#{branch_name}", force: true)
    end

    desc "finish", "Finish the branch and close the code review"
    option :offline, type: :boolean, desc: "Runs in offline mode"
    def finish
      branch_name
      confirm(:confirm_staging, "Has this been tested in a staging environment first?",
                                "Sorry, deploy to a staging environment first")
      confirm(:confirm_review, "Has this been code reviewed yet?",
                               "Please have someone look at this first")
      destination = (branch(:destination) || branch(:source))
      Zenflow::Branch.update(destination) if !options[:offline]
      Zenflow::Branch.checkout("#{flow}/#{branch_name}")
      Zenflow::Branch.merge(destination)
      update_version_and_changelog(version, changelog)
      merge_branches
      create_tag
      Zenflow::Branch.delete_remote("#{flow}/#{branch_name}") if !options[:offline]
      Zenflow::Branch.delete_local("#{flow}/#{branch_name}", force: true)
    end


    no_commands do
      def flow
        self.class.flow
      end

      def branch(key)
        val = all_branches(key)
        if val.size == 1
          val.first
        else
          val
        end
      end

      def all_branches(key)
        self.class.branch[key]
      end

      def version
        self.class.version
      end

      def changelog
        self.class.changelog
      end

      def tag
        self.class.tag
      end

      def create_pull_request
        already_created?(Zenflow::PullRequest.find_by_ref("#{flow}/#{branch_name}"))

        pull = Zenflow::PullRequest.create(
          base:  branch(:source),
          head:  "#{flow}/#{branch_name}",
          title: "#{flow}: #{branch_name}",
          body:  Zenflow::Ask("Describe this #{flow}:", required: true)
        )

        return handle_invalid_pull_request(pull) unless pull.valid?

        Zenflow::Log("Pull request was created!")
        Zenflow::Log(pull["html_url"], indent: true, color: false)
        Zenflow::Shell["open #{pull['html_url']}"]
      end

      def already_created?(pull)
        return unless pull
        Zenflow::Log("A pull request for #{flow}/#{branch_name} already exists", color: :red)
        Zenflow::Log(pull[:html_url], indent: true, color: false)
        exit(1)
      end

      def handle_invalid_pull_request(pull)
        Zenflow::Log("There was a problem creating the pull request:", color: :red)
        if pull["errors"]
          pull["errors"].each do |error|
            Zenflow::Log("* #{error['message'].gsub(/^base\s*/,'')}", indent: true, color: :red)
          end
        elsif pull["message"]
          Zenflow::Log("* #{pull['message']}", indent: true, color: :red)
        else
          Zenflow::Log(" * unexpected failure, both 'errors' and 'message' were empty in the response")
        end
      end

      def confirm(confirmation, question, failure_response)
        return unless Zenflow::Config[confirmation]
        if Zenflow::Ask(question, options: ["Y", "n"], default: "Y") == "n"
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
        Zenflow::Branch.push(:tags) if !options[:offline]
      end

      def merge_branches
        [branch(:source), branch(:destination)].compact.each do |finish|
          Zenflow::Branch.checkout(finish)
          Zenflow::Branch.merge("#{flow}/#{branch_name}")
          Zenflow::Branch.push(finish) if !options[:offline]
        end
      end
    end


  protected

    def branch_name
      @branch_name ||= Zenflow::Branch.current(flow) ||
                       Zenflow::Ask("Name of the #{flow}:",
                           required:      true,
                           validate:      /^[-0-9a-z]+$/,
                           error_message: "Names can only contain dashes, 0-9, and a-z").downcase
    end


    # DSL METHODS

    def self.flow(flow=nil)
      @flow = flow if flow
      @flow
    end

    def self.branch(branch={})
      @branch ||= {}
      branch.keys.each do |key|
        @branch[key] ||= []
        @branch[key] << branch[key]
      end
      @branch
    end

    def self.version(version=nil)
      @version = version if version
      @version
    end

    def self.changelog(changelog=nil)
      @changelog = changelog if changelog
      @changelog
    end

    def self.tag(tag=nil)
      @tag = tag if tag
      @tag
    end

  end
end
