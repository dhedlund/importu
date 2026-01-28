# frozen_string_literal: true

require "yaml"

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
