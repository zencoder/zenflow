module Zenflow

  module Github
    @@default_hub = 'github.com'

    def self.default_hub
      @@default_hub
    end

    @@system_default_api_base_url = 'https://api.github.com'

    @@api_base_url_key = 'api.base.url'

    def self.api_base_url(hub=nil,default=true)
      api_base_url = get_hub_config(hub, @@api_base_url_key)
      !api_base_url && default ? @@system_default_api_base_url : api_base_url
    end

    def self.set_api_base_url(hub=nil)
      api_base_url = Zenflow::Ask("What is the base URL of your Github API?", {:default => @@system_default_api_base_url})
      set_hub_config(hub, @@api_base_url_key, api_base_url)
    end

    @@user_key = 'github.user'

    def self.user(hub=nil)
      get_hub_config(hub, @@user_key)
    end

    def self.set_user(hub=nil)
      username = Zenflow::Ask("What is your Github username?")
      set_hub_config(hub, @@user_key, username)
    end

    @@token_key = 'token'

    def self.zenflow_token(hub=nil)
      get_hub_config(hub, @@token_key)
    end

    def self.authorize(hub=nil)
      Zenflow::Log("Authorizing with GitHub (#{user(hub)}@#{select_hub(hub)})... Enter your GitHub password.")
      oauth_response = JSON.parse(Zenflow::Shell.run(%{curl -u "#{Zenflow::Github.user(hub)}" #{Zenflow::Github.api_base_url(hub)}/authorizations -d '{"scopes":["repo"], "note":"Zenflow"}' --silent}, silent: true))
      if oauth_response['token']
        set_hub_config(hub, @@token_key, oauth_response['token'])
        Zenflow::Log("Authorized!")
      else
        Zenflow::Log("Something went wrong. Error from GitHub was: #{oauth_response['message']}")
        return
      end
    end

    @@system_default_user_agent_base = 'Zencoder'

    @@user_agent_base_key = 'user.agent.base'

    def self.user_agent_base(hub=nil,default=true)
      user_agent_base = get_hub_config(hub, @@user_agent_base_key)
      !user_agent_base && default ? @@system_default_user_agent_base : user_agent_base
    end

    def self.set_user_agent_base(hub=nil)
      user_agent_base = Zenflow::Ask("What base string would you like to use for the User Agent header, 'User-Agent: [user-agent-base]/Zenflow-#{VERSION}?", {:default => @@system_default_user_agent_base})
      set_hub_config(hub, @@user_agent_base_key, user_agent_base)
    end

    def self.select_hub(hub)
      if hub == 'default'
        hub = default_hub
      end
      if !hub
        hub = Zenflow::Repo.hub
      end
      if !hub
        hub = default_hub
      end

      hub
    end

    # If this repo is not hosted on the default github, construct a key prefix containing the hub information
    def self.key_for_hub(hub, key)
      default_hub_key_prefix = key == @@user_key ? "" : "zenflow."  # preserves backwards compatibility
      Zenflow::Repo.is_default_hub(hub) ? "#{default_hub_key_prefix}#{key}" : "zenflow.hub.#{hub}.#{key}"
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

    def self.config_keys
      [
        @@api_base_url_key,
        @@user_key,
        @@token_key,
        @@user_agent_base_key
      ]
    end

    def self.describe_hub_parameter(name, hub, key, value)
        [name, key_for_hub(hub, key), get_hub_config(hub, key), value]
    end

    def self.describe_hub(hub)
      [
        describe_hub_parameter("API Base URL",    hub, @@api_base_url_key,    api_base_url(hub)),
        describe_hub_parameter("User",            hub, @@user_key,            user(hub)),
        describe_hub_parameter("Token",           hub, @@token_key,           zenflow_token(hub)),
        describe_hub_parameter("User Agent Base", hub, @@user_agent_base_key, user_agent_base(hub))
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
