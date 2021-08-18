module Zenflow
  module Repo

    def self.url
      `git remote -v`[/^#{Zenflow::Config[:remote] || 'origin'}\s+(.*?)\s/, 1]
    end

    def self.hub
      return unless url

      if url[/git@/]
        url[/\w+@(.*?):.*?\.git/, 1]
      else
        url[%r{https://([^/]+)/(.*?)/(.*?)\.git}, 1]
      end
    end

    def self.slug
      return unless url

      if url[/git@/]
        url[/:(.*?)\.git/, 1]
      else
        url[%r{https://github.com/(.*?)\.git}, 1]
      end
    end
  end
end
