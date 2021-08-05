module Zenflow
  # Pull Request actions
  class PullRequest
    class << self
      def list
        response = Zenflow::GithubRequest.get("/pulls").parsed_response
        response.map { |pull| new(pull) }
      end

      def find(number)
        new(Zenflow::GithubRequest.get("/pulls/#{number}").parsed_response["pull"])
      end

      def find_by_ref(ref, options = {})
        Zenflow::Log("Looking up pull request for #{ref}") unless options[:silent]
        return unless list.any?

        pull = list.detect do |p|
          p["head"]["ref"] == ref
        end

        new(pull) if pull
      end

      def find_by_ref!(ref)
        pull = find_by_ref(ref)
        if pull
          new(pull)
        else
          Zenflow::Log("No open pull request was found for #{ref}", color: :red)
          exit(1)
        end
      end

      def exist?(ref)
        !!find_by_ref(ref)
      end

      def create(options = {})
        response = Zenflow::GithubRequest.post(
          "/pulls",
          body: {
            "base" => options[:base],
            "head" => options[:head],
            "title" => options[:title],
            "body" => options[:body]
          }.to_json
        )
        new(response.parsed_response)
      end
    end

    attr_reader :pull

    def initialize(pull)
      @pull = pull || {}
    end

    def valid?
      !pull["errors"] && pull['html_url']
    end

    def [](key)
      pull[key.to_s]
    end
  end
end
