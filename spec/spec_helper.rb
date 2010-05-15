
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. lib org-ruby]))
require 'erb'

RememberFile = File.join(File.dirname(__FILE__), %w[data remember.org])
FreeformFile = File.join(File.dirname(__FILE__), %w[data freeform.org])
FreeformExampleFile = File.join(File.dirname(__FILE__), %w[data freeform-example.org])

def process_erb_files(data_directory)
  erb_files = Dir.glob File.expand_path(File.join(data_directory, "*.erb" ))
  erb_files.each do |current_file|
    _output_file = current_file[0..-5]
    open(_output_file, "w") do |_of|
      _of.write ERB.new(File.read(current_file)).result(binding)
    end
  end
end


Spec::Runner.configure do |config|
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
end

