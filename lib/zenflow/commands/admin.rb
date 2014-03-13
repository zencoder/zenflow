module Zenflow
  class Admin < Thor

    desc "list", "Show all configured hubs."
    def list
      Zenflow::Log("Recogized hubs")
      Zenflow::Log(Terminal::Table.new(
        headings: ['Hub'],
        rows: get_list_of_hubs()
      ).to_s, indent: false, arrows: false, color: false)
    end

    desc "current", "Show the current project's hub."
    def current
      Zenflow::Log("This project's hub is #{hub_label(Zenflow::Github::CURRENT.hub)}")
    end

    desc "describe [HUB]", "Show configuration details for HUB (current project hub if none specified, or default if no current project)."
    def describe(hub=nil)
      hub = resolve_hub(hub)

      Zenflow::Log("Configuration details for hub #{hub_label(hub.hub)}")

      Zenflow::Log(Terminal::Table.new(
        headings: ["Parameter", "Github Config Key", "Github Config Value", "Value (with system defaults)"],
        rows: hub.describe
      ).to_s, indent: false, arrows: false, color: false)
    end

    desc "config [HUB]", "Configure the specified HUB (current project hub if none specified, or default hub if no current project)."
    def config(hub=nil)
      hub = resolve_hub(hub)

      Zenflow::Log("Configuring #{hub_label(hub.hub)}")

      hub.config
    end

    desc "authorize [HUB]", "Grab an auth token for HUB (current project hub if none specified, or default hub if no current project)."
    def authorize(hub=nil)
      hub = resolve_hub(hub)

      Zenflow::Log("Authorizing #{hub_label(hub.hub)}")

      hub.authorize
    end

    no_commands {
      def resolve_hub(hub=nil)
        hub = Zenflow::Github.new(hub) if hub
        hub ||= Zenflow::Github::CURRENT
      end

      def get_list_of_hubs
        hub_config_parameters = Zenflow::Shell.run("git config --get-regexp zenflow\.hub\..*", silent: true).split("\n")

        # unique, sorted, list of hubs with at least one valid config key
        configured_hubs = hub_config_parameters.inject([]) { |hubs, parameter|
          if parameter =~ /^zenflow\.hub\.(.*)\.#{config_keys_regex}\s.*$/
            hubs << [hub_label($1)]
          end

          hubs
        }.sort.uniq

        [
          ["#{hub_label(Zenflow::Github::DEFAULT_HUB)}"]
        ] + configured_hubs
      end

      def hub_label(hub)
        "#{hub}#{default_hub_tag(hub)}#{current_hub_tag(hub)}"
      end

      def default_hub_tag(hub)
        Zenflow::Repo.is_default_hub?(hub) ? " [default]" : ""
      end

      def current_hub_tag(hub)
        Zenflow::Repo.is_current_hub?(hub) ? " [current]" : ""
      end

      def config_keys_regex
        "(?:#{Zenflow::Github::CONFIG_KEYS.map { |s| s.gsub('.','\\.') }.join('|')})"
      end
    }
  end
end
