module Zenflow

  module Github
    def self.user
      user = Zenflow::Shell.run('git config --get github.user', silent: true)
      user = user.chomp unless user.nil?
      user
    end

    def self.zenflow_token
      zenflow_token = Zenflow::Shell.run('git config --get zenflow.token', silent: true)
      zenflow_token = zenflow_token.chomp unless zenflow_token.nil?
      zenflow_token
    end

    def self.authorize
      Zenflow::Log("Authorizing with GitHub... Enter your GitHub password.")
      oauth_response = JSON.parse(Zenflow::Shell.run(%{curl -u "#{Zenflow::Github.user}" https://api.github.com/authorizations -d '{"scopes":["repo"], "note":"Zenflow"}' --silent}, silent: true))
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
    headers "Authorization" => "token #{Zenflow::Github.zenflow_token}"
    headers "User-Agent" => "Zencoder/Zenflow-#{VERSION}"
  end

end
