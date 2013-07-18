module Zenflow

  module Github
    def self.get_config(key)
      config = Zenflow::Shell.run("git config --get #{key.to_s}", silent: true)
      config = config.chomp unless config.nil?
      config
    end

    def self.authorize
      Zenflow::Log("Authorizing with GitHub... Enter your GitHub password.")
      oauth_response = JSON.parse(Zenflow::Shell.run(%{curl -u "#{Zenflow::Github.get_config('github.user')}" https://api.github.com/authorizations -d '{"scopes":["repo"], "note":"Zenflow"}' --silent}, silent: true))
      if oauth_response['token']
        Zenflow::Shell.run("git config --global zenflow.token #{oauth_response['token']}", silent: true)
        Zenflow::Log("Authorized!")
      else
        Zenflow::Log("Something went wrong. Error from GitHub was: #{oauth_response['message']}")
        return
      end
    end

    def self.set_user
      username = Zenflow::Ask("What is your Github username?")
      Zenflow::Shell.run("git config --global github.user #{username}", silent: true)
    end
  end

  class GithubRequest
    include HTTParty
    base_uri "https://api.github.com/repos/#{Zenflow::Repo.slug}"
    format :json
    headers "Authorization" => "token #{Zenflow::Github.get_config('zenflow.token')}"
    headers "User-Agent" => "Zencoder/Zenflow-#{VERSION}"
  end

end
