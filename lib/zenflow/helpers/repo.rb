module Zenflow
  module Repo

    def self.url
      `git remote -v`[/^#{Zenflow::Config[:remote] || 'origin'}\s+(.*?)\s/, 1]
    end

    def self.hub
      (url && url[/\w+@(.*?):.*?\.git/, 1]) || nil
    end

    def self.slug
      (url && url[/:(.*?)\.git/, 1]) || nil
    end

    def self.is_current_hub(check)
      hub == check
    end

    def self.is_default_hub(check=nil)
      (check ? check : hub) == Zenflow::Github.default_hub
    end

    def self.is_system_default_hub(check=nil)
      (check ? check : hub) == Zenflow::Github.system_default_hub
    end

  end
end
