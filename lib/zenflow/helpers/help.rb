module Zenflow

  def self.Help(options={})
    Zenflow::Help.new(options)
  end

  class Help
    attr_accessor :options

    def initialize(options={})
      @options = options
    end

    def title(text)
      Rainbow("- #{text} ".ljust(40, "-")).cyan
    end

    def banner
      help = []
      help << "#{title("Summary")}\n#{options[:summary]}" if options[:summary]
      help << "#{title("Usage")}\n#{options[:usage]}" if options[:usage]
      help << "#{title("Available Commands")}\n#{options[:commands]}" if options[:commands]
      help << "#{title("Options")}"
      help.join("\n\n")
    end

    def unknown_command
      if options[:command].nil?
        Zenflow::Log("Missing command", :color => :red)
      else
        Zenflow::Log("Unknown command #{options[:command].inspect}", :color => :red)
      end
      exit(1)
    end
  end

end
