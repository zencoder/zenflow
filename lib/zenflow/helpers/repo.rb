module Zenflow
  module Repo

    def self.url
      `git remote -v`[/^#{Zenflow::Config[:remote] || 'origin'}\s+(.*?)\s/, 1]
    end

    def self.slug
      (url && url[/:(.*?)\.git/, 1]) || nil
    end

  end
end
