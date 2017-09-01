SimpleCov.start do
  add_filter do |source_file|
    # Filter out all files that are not in the gem's lib/ directory
    source_file.filename.start_with?("#{SimpleCov.root}/lib/") == false
  end
end if ENV["COVERAGE"]
