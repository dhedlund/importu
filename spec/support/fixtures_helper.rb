module FixturesHelper
  def infile(name, ext)
    File.join(fixtures_path, name, "infile.#{ext}")
  end

  def expected_model_json(name)
    load_fixture_json(name, "model.json")
  end

  def expected_summary_json(name)
    load_fixture_json(name, "summary.json")
  end

  def fixtures_path
    File.expand_path("../../fixtures", __FILE__)
  end

  private def load_fixture_json(*path_parts)
    @fixture_json_cache ||= Hash.new do |hash, name|
      data = File.read(File.join(fixtures_path, *path_parts))
      JSON.parse(data)
    end

    @fixture_json_cache[path_parts]
  end

end
