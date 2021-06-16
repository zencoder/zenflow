module Zenflow

  LOG_PATH = File.join(Dir.pwd, ".zenflow-log")

  def self.Log(message, options={})
    output = ""
    output << "       " if options[:indent]
    output << "-----> " if !(options[:arrows] === false)
    output << message
    LogToFile(output)
    output = Rainbow(output).send(options[:color] || :cyan) unless options[:color] == false
    puts output
  end

  def self.LogToFile(message)
    File.open(LOG_PATH, "a") do |f|
      f.write(message+"\n")
    end
  end

end
