module Zenflow

  def self.Ask(question, options={})
    response = Zenflow::Query.ask_question(question, options)
    Zenflow::Query.handle_response(response, options)
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

  class Query
    def self.ask_question(question, options={})
      if options[:response].to_s.strip != ""
        response = options[:response]
      else
        response = Zenflow::Query.prompt_for_answer(question, options)
      end
      Zenflow::LogToFile("Response: #{response}")
      response
    end

    def self.prompt_for_answer(question, options={})
      prompt = ">> #{question} "
      prompt << "[#{options[:options].join('/')}] " if options[:options]
      prompt << "[#{options[:default]}] " if options[:default] && !options[:options]
      Zenflow::LogToFile("Asked: #{prompt}")
      print prompt
      $stdin.gets.chomp
    end

    def self.handle_response(response, options={})
      if !Zenflow::Query.valid_response?(response, options)
        raise Zenflow::Query.build_error_message(response, options)
      end

      return options[:default].downcase if response == ""
      return response.downcase if response == "Y" || response == "N"
      response
    end

    def self.valid_response?(response, options={})
      if response == ''
        response = options[:default].downcase if options[:default]
      end

      response.downcase! unless options[:response]

      if options[:options]
        options[:options].map!(&:downcase)
      end

      return false if options[:options] && !options[:options].include?(response)
      return false if options[:validate] && options[:validate].is_a?(Regexp) && !response[options[:validate]]
      return false if options[:required] && response == ""
      true
    end

    def self.build_error_message(response, options={})
      if options[:required]
        message = "You must respond to this prompt."
      elsif options[:error_message]
        message = options[:error_message]
      else
        message = %{"#{response}" is not a valid response.}
      end
      "-----> #{message} Try again.".red
    end
  end

end
