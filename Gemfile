# frozen_string_literal: true
source "http://rubygems.org"

# Specify your gem's dependencies in importu.gemspec
gemspec

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem "pry"
gem "coveralls", require: false

# A fork of dkubb/yardstick until the upstream gem has support for project-
# level config overrides. See https://github.com/dkubb/yardstick/pull/50
gem "yardstick", github: "dhedlund/yardstick", branch: "default-config-yml", require: false
