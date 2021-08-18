module Zenflow

  def self.Deploy(to, opts={})
    Branch.push(to)
    if opts[:migrations]
      message = "Deploying with migrations to #{to}"
      command = "cap #{to} deploy:migrations"
    else
      message = "Deploying to #{to}"
      command = "cap #{to} deploy"
    end

    Log(message)
    if opts[:trace]
      Shell[command + ' --trace']
    else
      Shell[command]
    end
  end

  class Deploy < Thor
    class_option :migrations, type: :boolean, desc: "Run migrations during deployment", aliases: :m
    class_option :trace, type: :boolean, desc: "Run capistrano trace option", aliases: :t

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
