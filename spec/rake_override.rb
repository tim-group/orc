require 'rubygems'
require 'rake'
require 'rake/dsl_definition'
require 'rspec/core/rake_task'

module SingleTestFilePerInterpreterSpec
  class RakeTask < RSpec::Core::RakeTask
    def initialize(*args)
      setup_ivars(args)

      desc("Run RSpec code examples") unless ::Rake.application.last_comment

      task name do
        RakeFileUtils.send(:verbose, verbose) do
          if files_to_run.empty?
            puts "No examples matching #{pattern} could be found"
          else
            files_to_run.each do |f|
              meta = class << self; self; end
              meta.send(:define_method, :files_to_run) { return f }

              begin
                puts spec_command if verbose
                success = system('export INSIDE_RSPEC=true; ' + spec_command)
              rescue
                puts failure_message if failure_message
              end
              fail("#{spec_command} failed") if fail_on_error unless success
              @spec_command = nil
            end
          end
        end
      end
    end
  end
end
