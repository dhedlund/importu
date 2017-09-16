require 'simplecov'

# Only setup coveralls support if on CI environment or explicitly requested
# to run. This is necessary to make simplecov still generate result files,
# as well as keeping colorful simplecov messages from showing in local runs.
if ENV["CI"] || ENV["JENKINS_URL"] || ENV["COVERALLS_RUN_LOCALLY"]
  require 'coveralls'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter,
  ])

  Coveralls.wear_merged!
end

# Make each appraisal have a unique simplecov name. Needed to allow merging
# of results since each appraisal may only run a subset of relevant specs.
gemfile = ENV.fetch("BUNDLE_GEMFILE", "system")
SimpleCov.command_name "appraisal:#{File.basename(gemfile, ".gemfile")}"

SimpleCov.start do
  add_filter do |source_file|
    # Filter out all files that are not in the gem's lib/ directory
    source_file.filename.start_with?("#{SimpleCov.root}/lib/") == false
  end
end if ENV["COVERAGE"] || defined?(::Coveralls)
