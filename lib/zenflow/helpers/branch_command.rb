module Zenflow
  class BranchCommand < Thor

    include Zenflow::BranchCommands::Abort
    include Zenflow::BranchCommands::Branches
    include Zenflow::BranchCommands::Compare
    include Zenflow::BranchCommands::Deploy
    include Zenflow::BranchCommands::Diff
    include Zenflow::BranchCommands::Finish
    include Zenflow::BranchCommands::Review
    include Zenflow::BranchCommands::Start
    include Zenflow::BranchCommands::Update

    no_commands do
      def flow
        self.class.flow
      end

      def branch(key)
        val = all_branches(key)
        if val && val.size == 1
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

      def delete_branches
        Zenflow::Branch.delete_remote("#{flow}/#{branch_name}") if !options[:offline]
        Zenflow::Branch.delete_local("#{flow}/#{branch_name}", :force => true)
      end

    end


  protected

    #TODO: move the validation regex to a single place
    def branch_name
      @branch_name ||= Zenflow::Branch.current(flow) ||
                       Zenflow::Ask("Name of the #{flow}:",
                           :required => true,
                           :validate => /^[-_0-9a-z]+$/,
                           :error_message => "Names can only contain dashes, underscores, 0-9, and a-z").downcase
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
