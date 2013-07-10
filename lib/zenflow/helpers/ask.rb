module Zenflow

  def self.Ask(question, options={})
    if options[:response] && options[:response].strip != ""
      response = options[:response]
    else
      prompt = ">> #{question} "
      prompt << "[#{options[:options].join('/')}] " if options[:options]
      prompt << "[#{options[:default]}] " if options[:default] && !options[:options]
      LogToFile("Asked: #{prompt}")
      print prompt
      response = $stdin.gets.chomp
    end
    LogToFile("Response: #{response}")
    if response != ""
      if options[:options] && !options[:options].include?(response)
        raise %{-----> "#{response}" is not a valid response. Try again.}.red
      elsif options[:validate] && options[:validate].is_a?(Regexp) && !response[options[:validate]]
        raise "-----> "+(options[:error_message] || %{"#{response}" is not a valid response. Try again.})
      else
        if response == "Y" || response == "N"
          response.downcase
        else
          response
        end
      end
    elsif options[:required]
      raise %{-----> You must respond to this prompt. Try again.}.red
    else
      options[:default].downcase
    end
  rescue StandardError => e
    puts e.message
    options[:response] = nil
    retry
  rescue Interrupt => e
    puts
    puts "-----> Exiting...".cyan
    LogToFile("-----> Received interrupt. Exiting...")
    exit(1)
  end

end
