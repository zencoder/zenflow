guard :rspec, :focus_on_failed => true do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})         { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^lib/zenflow/(.+)\.rb$}) { |m| "spec/zenflow/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')      { "spec" }
end
