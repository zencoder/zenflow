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
    class_option :migrations, :type => :boolean, :desc => "Run migrations during deployment", :aliases => :m

    desc "qa", "Deploy to qa."
    def qa
      Zenflow::Deploy("qa", options)
    end

    desc "staging", "Deploy to staging."
    def staging
      Zenflow::Deploy("staging", options)
    end

    desc "production", "Deploy to production."
    def production
      Zenflow::Deploy("production", options)
    end
  end

end
