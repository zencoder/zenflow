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
    def init(force=true)
      already_configured if Zenflow::Config.configured? && !force
      authorize_github
      Zenflow::Log("Project")
      Zenflow::Config[:project] = Zenflow::Ask("What is the name of this project?", :required => true)
      Zenflow::Log("Branches")
      Zenflow::Config[:development_branch] = Zenflow::Ask("What is the name of the main development branch?", :default => "master")
      configure_staging_branch
      configure_qa_branch
      if Zenflow::Ask("Use a release branch?", :options => ["Y", "n"], :default => "Y") == "y"
        Zenflow::Config[:release_branch] = Zenflow::Ask("What is the name of the release branch?", :default => "production")
      else
        Zenflow::Config[:release_branch] = false
      end
      Zenflow::Config[:remote] = Zenflow::Ask("What is the name of your primary remote?", :default => "origin")
      if Zenflow::Ask("Use a backup remote?", :options => ["Y", "n"], :default => "n") == "y"
        Zenflow::Config[:backup_remote] = Zenflow::Ask("What is the name of your backup remote?", :default => "backup")
      else
        Zenflow::Config[:backup_remote] = false
      end
      Zenflow::Log("Confirmations")
      Zenflow::Config[:confirm_staging] = Zenflow::Ask("Require deployment to a staging environment?", :options => ["Y", "n"], :default => "Y") == "y"
      Zenflow::Config[:confirm_review] = Zenflow::Ask("Require code reviews?", :options => ["Y", "n"], :default => "Y") == "y"
      if !File.exist?("CHANGELOG.md")
        Zenflow::Log("Changelog Management")
        if Zenflow::Ask("Set up a changelog?", :options => ["Y", "n"], :default => "Y") == "y"
          Zenflow::Changelog.create
        end
      end
      Zenflow::Config.save!
    end

    desc "authorize_github", "Get an auth token from GitHub"
    def authorize_github
      if Zenflow::Github.zenflow_token
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

      def configure_staging_branch
        if Zenflow::Ask("Use a branch for staging releases and hotfixes?", :options => ["Y", "n"], :default => "Y") == "y"
          Zenflow::Config[:staging_branch] = Zenflow::Ask("What is the name of that branch?", :default => "staging")
        else
          Zenflow::Config[:staging_branch] = false
        end
      end

      def configure_qa_branch
        if Zenflow::Ask("Use a branch for testing features?", :options => ["Y", "n"], :default => "Y") == "y"
          Zenflow::Config[:qa_branch] = Zenflow::Ask("What is the name of that branch?", :default => "qa")
        else
          Zenflow::Config[:qa_branch] = false
        end
      end

    end

  end
end
