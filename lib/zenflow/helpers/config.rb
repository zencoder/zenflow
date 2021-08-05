module Zenflow
  # Configuration settings
  class Config
    class << self
      attr_accessor :config

      CONFIG_FILE = "#{Dir.pwd}/.zenflow".freeze

      def load!
        @config = {}
        @config = YAML.load_file(CONFIG_FILE) if configured?
      end

      def save!
        File.open(CONFIG_FILE, "w") do |out|
          YAML.dump(@config, out)
        end
      end

      def [](key)
        load!
        @config[key.to_s]
      end

      def []=(key, value)
        load!
        @config[key.to_s] = value
        save!
      end

      def configured?
        File.exist?(CONFIG_FILE)
      end
    end
  end
end
