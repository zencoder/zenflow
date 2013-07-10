module Zenflow

  def self.Deploy(to, opts={})
    Branch.push(to)
    if opts[:migrations]
      Log("Deploying with migrations to #{to}")
      Shell["cap #{to} deploy:migrations"]
    else
      Log("Deploying to #{to}")
      Shell["cap #{to} deploy"]
    end
  end

  class Deploy < Thor
    class_option :migrations, type: :boolean, desc: "Run migrations during deployment", aliases: :m

    desc "qa", "Deply to qa."
    def qa
      Deploy("qa", options)
    end

    desc "staging", "Deply to staging."
    def staging
      Deploy("staging", options)
    end

    desc "production", "Deply to production."
    def production
      Deploy("production", options)
    end
  end

end
