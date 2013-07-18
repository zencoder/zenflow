module Zenflow
  class CLI < Thor

    map "-v" => "version", "--version" => "version"
    map "-h" => "help", "--help" => "help"

    desc "version", "Show zenflow version.", :hide => true
    def version
      puts "Zenflow #{Zenflow::VERSION}"
    end

    desc "help", "Show zenflow help.", :hide => true
    def help
      version
      puts
      puts "Options:"
      puts "  -h, --help      # Prints help"
      puts "  -v, --version   # Prints Zenflow version"
      puts
      super
    end

    desc "feature SUBCOMMAND", "Manage feature branches."
    subcommand "feature", Zenflow::Feature

    desc "hotfix SUBCOMMAND", "Manage hotfix branches."
    subcommand "hotfix", Zenflow::Hotfix

    desc "release SUBCOMMAND", "Manage release branches."
    subcommand "release", Zenflow::Release

    desc  "reviews SUBCOMMAND", "Works with code reviews."
    subcommand "reviews", Zenflow::Reviews

    desc  "deploy ENV", "Deploy to an environment."
    subcommand "deploy", Zenflow::Deploy

    desc "init", "Write the zenflow config file."
    def init(force=false)
      already_configured if Zenflow::Config.configured? && !force
      set_up_github
      authorize_github
      configure_project
      configure_branches
      configure_remotes
      confirm_some_stuff
      set_up_changelog
      Zenflow::Config.save!
    end

    desc "set_up_github", "Set up GitHub user information"
    def set_up_github
      user = Zenflow::Github.get_config('github.user')
      if user.to_s != ''
        if Zenflow::Ask("Your GitHub user is currently #{user}. Do you want to use that?", :options => ["y", "N"], :default => "Y") == "n"
          Zenflow::Github.set_user
        end
      else
        Zenflow::Github.set_user
      end
    end

    desc "authorize_github", "Get an auth token from GitHub"
    def authorize_github
      if Zenflow::Github.get_config('zenflow.token')
        if Zenflow::Ask("You already have a token from GitHub. Do you want to set a new one?", :options => ["Y", "n"], :default => "Y") == "y"
          Zenflow::Github.authorize
        end
      else
        Zenflow::Github.authorize
      end
    end

    no_commands do

      def already_configured
        Zenflow::Log("Warning", :color => :red)
        if Zenflow::Ask("There is an existing config file. Overwrite it?", :options => ["y", "N"], :default => "N") == "y"
          init(true)
        else
          Zenflow::Log("Aborting...", :color => :red)
          exit(1)
        end
      end

      def configure_project
        Zenflow::Log("Project")
        Zenflow::Config[:project] = Zenflow::Ask("What is the name of this project?", :required => true)
      end

      def configure_branches
        Zenflow::Log("Branches")
        Zenflow::Config[:development_branch] = Zenflow::Ask("What is the name of the main development branch?", :default => "master")
        configure_branch(:staging_branch, "Use a branch for staging releases and hotfixes?", "staging")
        configure_branch(:qa_branch, "Use a branch for testing features?", "qa")
        configure_branch(:release_branch, "Use a release branch?", "production")
      end

      def configure_branch(branch, question, default)
        if Zenflow::Ask(question, :options => ["Y", "n"], :default => "Y") == "y"
          Zenflow::Config[branch] = Zenflow::Ask("What is the name of that branch?", :default => default)
        else
          Zenflow::Config[branch] = false
        end
      end

      def configure_remotes
        Zenflow::Config[:remote] = Zenflow::Ask("What is the name of your primary remote?", :default => "origin")
        if Zenflow::Ask("Use a backup remote?", :options => ["Y", "n"], :default => "n") == "y"
          Zenflow::Config[:backup_remote] = Zenflow::Ask("What is the name of your backup remote?", :default => "backup")
        else
          Zenflow::Config[:backup_remote] = false
        end
      end

      def set_up_changelog
        return if File.exist?("CHANGELOG.md")
        Zenflow::Log("Changelog Management")
        Zenflow::Changelog.create if Zenflow::Ask("Set up a changelog?", :options => ["Y", "n"], :default => "Y") == "y"
      end

      def confirm_some_stuff
        Zenflow::Log("Confirmations")
        Zenflow::Config[:confirm_staging] = Zenflow::Ask("Require deployment to a staging environment?", :options => ["Y", "n"], :default => "Y") == "y"
        Zenflow::Config[:confirm_review] = Zenflow::Ask("Require code reviews?", :options => ["Y", "n"], :default => "Y") == "y"
      end

    end

  end
end
