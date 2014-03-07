module Zenflow

  module Github
    DEFAULT_HUB = 'github.com'

    DEFAULT_API_BASE_URL = 'https://api.github.com'
    DEFAULT_USER_AGENT_BASE = 'Zencoder'

    API_BASE_URL_KEY = 'api.base.url'
    USER_KEY = 'github.user'
    TOKEN_KEY = 'token'
    USER_AGENT_BASE_KEY = 'user.agent.base'

    CONFIG_KEYS = [
      API_BASE_URL_KEY,
      USER_KEY,
      TOKEN_KEY,
      USER_AGENT_BASE_KEY
    ]

    def self.api_base_url(hub=nil,default=true)
      api_base_url = get_hub_config(hub, API_BASE_URL_KEY)
      !api_base_url && default ? DEFAULT_API_BASE_URL : api_base_url
    end

    def self.set_api_base_url(hub=nil)
      api_base_url = Zenflow::Ask("What is the base URL of your Github API?", {:default => DEFAULT_API_BASE_URL})
      set_hub_config(hub, API_BASE_URL_KEY, api_base_url)
    end

    def self.user(hub=nil)
      get_hub_config(hub, USER_KEY)
    end

    def self.set_user(hub=nil)
      username = Zenflow::Ask("What is your Github username?")
      set_hub_config(hub, USER_KEY, username)
    end

    def self.zenflow_token(hub=nil)
      get_hub_config(hub, TOKEN_KEY)
    end

    def self.authorize(hub=nil)
      Zenflow::Log("Authorizing with GitHub (#{user(hub)}@#{select_hub(hub)})... Enter your GitHub password.")
      oauth_response = JSON.parse(Zenflow::Shell.run(%{curl -u "#{Zenflow::Github.user(hub)}" #{Zenflow::Github.api_base_url(hub)}/authorizations -d '{"scopes":["repo"], "note":"Zenflow"}' --silent}, silent: true))
      if oauth_response['token']
        set_hub_config(hub, TOKEN_KEY, oauth_response['token'])
        Zenflow::Log("Authorized!")
      else
        Zenflow::Log("Something went wrong. Error from GitHub was: #{oauth_response['message']}")
        return
      end
    end

    def self.user_agent_base(hub=nil,default=true)
      user_agent_base = get_hub_config(hub, USER_AGENT_BASE_KEY)
      !user_agent_base && default ? DEFAULT_USER_AGENT_BASE : user_agent_base
    end

    def self.set_user_agent_base(hub=nil)
      user_agent_base = Zenflow::Ask("What base string would you like to use for the User Agent header, 'User-Agent: [user-agent-base]/Zenflow-#{VERSION}?", {:default => DEFAULT_USER_AGENT_BASE})
      set_hub_config(hub, USER_AGENT_BASE_KEY, user_agent_base)
    end

    def self.select_hub(hub)
      hub = DEFAULT_HUB if hub == "default"
      hub || Zenflow::Repo.hub || DEFAULT_HUB
    end

    # If this repo is not hosted on the default github, construct a key prefix containing the hub information
    def self.key_for_hub(hub, key)
      default_hub_key_prefix = key == USER_KEY ? "" : "zenflow."  # preserves backwards compatibility
      Zenflow::Repo.is_default_hub?(hub) ? "#{default_hub_key_prefix}#{key}" : "zenflow.hub.#{hub}.#{key}"
    end

    def self.get_hub_config(hub, key)
      get_global_config(key_for_hub(select_hub(hub), key))
    end

    def self.set_hub_config(hub, key, value)
      set_global_config(key_for_hub(select_hub(hub), key), value)
    end

    def self.get_global_config(key)
      config = Zenflow::Shell.run("git config --get #{key.to_s}", silent: true)
      config = config.chomp unless config.nil?
      config.to_s == '' ? nil : config
    end

    def self.set_global_config(key, value)
      Zenflow::Shell.run("git config --global #{key} #{value}", silent: true)
    end

    def self.describe_hub_parameter(name, hub, key, value)
      [name, key_for_hub(hub, key), get_hub_config(hub, key), value]
    end

    def self.describe_hub(hub)
      [
        describe_hub_parameter("API Base URL",    hub, API_BASE_URL_KEY,    api_base_url(hub)),
        describe_hub_parameter("User",            hub, USER_KEY,            user(hub)),
        describe_hub_parameter("Token",           hub, TOKEN_KEY,           zenflow_token(hub)),
        describe_hub_parameter("User Agent Base", hub, USER_AGENT_BASE_KEY, user_agent_base(hub))
      ]
    end
  end

  class GithubRequest
    include HTTParty
    base_uri "#{Zenflow::Github.api_base_url}/repos/#{Zenflow::Repo.slug}"
    format :json
    headers "Authorization" => "token #{Zenflow::Github.zenflow_token}"
    headers "User-Agent" => "#{Zenflow::Github.user_agent_base}/Zenflow-#{VERSION}"
  end

end
