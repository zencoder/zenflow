module Zenflow
  class PullRequest

    class << self
      def list
        pulls = Zenflow::GithubRequest.get("/pulls").parsed_response.include?("pulls") ? Zenflow::GithubRequest.get("/pulls").parsed_response["pulls"] : []
        pulls.map{ |pull| new(pull) }
      end

      def find(number)
        new(Zenflow::GithubRequest.get("/pulls/#{number}").parsed_response["pull"])
      end

      def find_by_ref(ref, options={})
        Zenflow::Log("Looking up pull request for #{ref}") unless options[:silent]
        if !list.nil?
          pull = list.detect do |p|
            p["head"]["ref"] == ref
          end
          if pull
            new(pull)
          end
        end
      end

      def find_by_ref!(ref)
        Zenflow::Log("Looking up pull request for #{ref}")
        if pull = find_by_ref(ref, :silent => true)
          new(pull)
        else
          Zenflow::Log("No open pull request was found for #{ref}", :color => :red)
          exit(1)
        end
      end

      def exist?(ref)
        !!find_by_ref(ref)[:number]
      end

      def create(options={})
        response = Zenflow::GithubRequest.post("/pulls",
          :body => {
            "base"  => options[:base],
            "head"  => options[:head],
            "title" => options[:title],
            "body"  => options[:body]
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
