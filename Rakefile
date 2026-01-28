# frozen_string_literal: true

require "yaml"

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # rspec not available
end

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:rubocop)
rescue LoadError
  # rubocop not available
end

begin
  require "yardstick/rake/verify"

  config = YAML.safe_load_file(".yardstick.yml")

  Yardstick::Rake::Verify.new(:yardstick_verify, config) do |verify|
    verify.threshold = config.fetch("threshold", 100)
  end

  task yardstick: :yardstick_verify
rescue LoadError
  # yardstick not available
end

desc "Run all checks before release (specs, rubocop, yardstick)"
task :preflight do
  puts "=== Preflight Checks ===\n\n"

  # Check for uncommitted changes
  uncommitted = `git status --porcelain`.strip
  unless uncommitted.empty?
    puts "WARNING: Uncommitted changes detected:"
    puts uncommitted.lines.map { |l| "  #{l}" }.join
    puts
  end

  # Run checks
  checks = [
    ["RSpec", "spec"],
    ["RuboCop", "rubocop"],
    ["YARD Coverage", "yardstick"]
  ]

  failed = []

  checks.each do |name, task_name|
    print "Running #{name}... "
    begin
      Rake::Task[task_name].invoke
      puts "OK"
    rescue SystemExit, RuntimeError
      puts "FAILED"
      failed << name
    end
  end

  puts
  if failed.any?
    abort "Preflight FAILED: #{failed.join(", ")}"
  else
    puts "All preflight checks passed."
  end
end
