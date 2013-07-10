module Zenflow
  module Branch
    class << self

      def list(prefix)
        branches = Zenflow::Shell.run "git branch | grep #{prefix}", :silent => true
        return ['!! NONE !!'] if branches.empty?
        branches.split("\n").map{|branch| branch.sub(/.*#{prefix}\/?/, "") }
      end

      def current(prefix)
        branch = Zenflow::Shell.run("git branch | grep '* #{prefix}'", :silent => true)
        branch.chomp.sub(/\* #{prefix}\/?/, "") unless branch.empty?
      end

      def update(name)
        Zenflow::Log("Updating the #{name} branch")
        Zenflow::Shell["git checkout #{name} && git pull"]
      end

      def create(name, base)
        Zenflow::Log("Creating the #{name} branch based on #{base}")
        Zenflow::Shell["git checkout -b #{name} #{base}"]
      end

      def push(name)
        Zenflow::Log("Pushing the #{name} branch to #{Zenflow::Config[:remote] || 'origin'}")
        Zenflow::Shell["git push #{Zenflow::Config[:remote] || 'origin'} #{name}"]
        if Zenflow::Config[:backup_remote]
          Zenflow::Log("Pushing the #{name} branch to #{Zenflow::Config[:backup_remote]}")
          Zenflow::Shell["git push #{Zenflow::Config[:backup_remote]} #{name}"]
        end
      end

      def push_tags
        Zenflow::Log("Pushing tags to #{Zenflow::Config[:remote] || 'origin'}")
        Zenflow::Shell["git push #{Zenflow::Config[:remote] || 'origin'} --tags"]
        if Zenflow::Config[:backup_remote]
          Zenflow::Log("Pushing tags to #{Zenflow::Config[:backup_remote]}")
          Zenflow::Shell["git push #{Zenflow::Config[:backup_remote]} --tags"]
        end
      end

      def track(name)
        Zenflow::Log("Tracking the #{name} branch against #{Zenflow::Config[:remote] || 'origin'}/#{name}")
        Zenflow::Shell["git branch --set-upstream #{name} #{Zenflow::Config[:remote] || 'origin'}/#{name}"]
      end

      def checkout(name)
        Zenflow::Log("Switching to the #{name} branch")
        Zenflow::Shell["git checkout #{name}"]
      end

      def merge(name)
        Zenflow::Log("Merging in the #{name} branch")
        Zenflow::Shell["git merge --no-ff #{name}"]
      end

      def tag(name=nil, description=nil)
        Zenflow::Log("Tagging the release")
        Zenflow::Shell["git tag -a '#{name || Zenflow::Ask('Name of the tag:', :required => true)}' -m '#{Zenflow::Shell.shell_escape_for_single_quoting((description || Zenflow::Ask('Tag message:', :required => true)).to_s)}'"]
      end

      def delete_remote(name)
        Zenflow::Log("Removing the remote branch from #{Zenflow::Config[:remote] || 'origin'}")
        Zenflow::Shell["git branch -r | grep #{Zenflow::Config[:remote] || 'origin'}/#{name} && git push #{Zenflow::Config[:remote] || 'origin'} :#{name} || echo ''"]
        if Zenflow::Config[:backup_remote]
          Zenflow::Log("Removing the remote branch from #{Zenflow::Config[:backup_remote]}")
          Zenflow::Shell["git branch -r | grep #{Zenflow::Config[:backup_remote]}/#{name} && git push #{Zenflow::Config[:backup_remote]} :#{name} || echo ''"]
        end
      end

      def delete_local(name, options={})
        Zenflow::Log("Removing the local branch")
        Zenflow::Shell["git branch -#{options[:force] ? 'D' : 'd'} #{name}"]
      end

    end
  end
end
