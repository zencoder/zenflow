module Zenflow
  # Reviews actions
  class Reviews < Thor
    desc "list", "Show all open reviews."
    def list
      Zenflow::Log(
        Terminal::Table.new(
          rows: Zenflow::PullRequest.list.map do |request|
            [request["number"], request["head"]["ref"]]
          end
        ).to_s,
        indent: false,
        arrows: false,
        color: false
      )
    end
  end
end
