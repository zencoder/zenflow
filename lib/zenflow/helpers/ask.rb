module Zenflow
  # Requiring information from the user
  module Requests
    def self.ask(question, options = {})
      response = Zenflow::Requests::Query.ask_question(question, options)
      Zenflow::Requests::Query.handle_response(response, options)
    rescue StandardError => e
      puts e.message
      options[:response] = nil

      print '>> Retry? [Y/n]'
      retry_response = $stdin.gets.chomp
      retry if ['y', 'yes', ''].include? retry_response.downcase
      puts Rainbow("-----> Exiting...").cyan
      Zenflow::LogToFile("-----> Received bad response with no retry. Exiting...")
      exit(1)
    rescue Interrupt => e
      puts
      puts Rainbow("-----> Exiting...").cyan
      Zenflow::LogToFile("-----> Received interrupt. Exiting...")
      exit(1)
    end

    # Specific queries definitions
    class Query
      def self.ask_question(question, options = {})
        response = if options[:response].to_s.strip != ""
                     options[:response]
                   else
                     Zenflow::Requests::Query.prompt_for_answer(question, options)
                   end
        Zenflow::LogToFile("Response: #{response}")
        response
      end

      def self.prompt_for_answer(question, options = {})
        prompt = ">> #{question} "
        prompt << "[#{options[:options].join('/')}] " if options[:options]
        prompt << "[#{options[:default]}] " if options[:default] && !options[:options]
        Zenflow::LogToFile("Asked: #{prompt}")
        print prompt
        $stdin.gets.chomp
      end

      def self.handle_response(response, options = {})
        unless Zenflow::Requests::Query.valid_response?(response, options)
          raise Zenflow::Requests::Query.build_error_message(response, options)
        end

        return options[:default].downcase if response == ""
        return response.downcase if ["Y", "N"].include? response

        response
      end

      def self.valid_response?(response, options = {})
        response = normalize_response(response, options[:default])
        options[:options]&.map!(&:downcase)

        return false if options[:options] && !options[:options].include?(response)
        return false if options[:validate].is_a?(Regexp) && !response[options[:validate]]
        return false if options[:required] && response == ""

        true
      end

      def self.build_error_message(response, options = {})
        message = if options[:required]
                    "You must respond to this prompt with a valid response."
                  elsif options[:error_message]
                    options[:error_message]
                  else
                    %("#{response}" is not a valid response.)
                  end
        Rainbow("-----> #{message} Try again.").red
      end

      def self.normalize_response(primary_response, secondary_response)
        return secondary_response.downcase if primary_response.to_s == '' && !secondary_response.nil?

        primary_response.downcase
      end
    end
  end
end
