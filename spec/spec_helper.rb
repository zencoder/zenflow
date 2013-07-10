require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'

  add_group 'Helpers', 'lib/zenflow/helpers'
end

Dir["./spec/support/**/*.rb"].sort.each {|f| require f}
require 'zenflow'

RSpec.configure do |config|
  config.order = "random"
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus => true

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end
    result
  end
end
