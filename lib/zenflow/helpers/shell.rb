module Zenflow
  class Shell
    class << self

      def failed!(x)
        @failed = true
        @status = x
      end

      def failed?
        !!@failed
      end

      def status
        @status || 0
      end

      def [](command)
        run(command)
      end

      def run(command, options={})
        if options[:silent]
          Zenflow::LogToFile("$ #{command}\n")
        else
          Zenflow::Log("$ #{command}", arrows: false, color: :yellow)
        end
        if !failed?
          if options[:silent]
            run_without_output(command, options)
          else
            run_with_output(command, options)
          end
        end
      end

      def run_with_output(command, options={})
        output = run_with_result_check(command, options)
        if output.strip != ""
          puts "#{output.strip}\n"
        end
        output
      end

      def run_without_output(command, options={})
        output = ""
        log_stream(STDERR) do
          output = run_with_result_check(command, options)
        end
        output
      end

      def run_with_result_check(command, options={})
        output = `#{command}`
        Zenflow::LogToFile(output)
        if last_exit_status.to_i > 0
          if output.strip != ""
            puts "#{output.strip}\n"
          end
          Zenflow::Log("Process aborted", color: :red)
          Zenflow::Log("Exit status: #{last_exit_status}", color: :red, indent: true)
          Zenflow::Log("You may need to run any following commands manually...", color: :red)
          failed!($?.to_i)
        end
        output
      end

      def last_exit_status
        $?
      end

      def shell_escape_for_single_quoting(string)
        string.gsub("'","'\\\\''")
      end


      # Stolen from ActiveSupport
      def log_stream(stream)
        old_stream = stream.dup
        stream.reopen(Zenflow::LOG_PATH, "a")
        stream.sync = true
        yield
      ensure
        stream.reopen(old_stream)
      end

    end
  end
end
