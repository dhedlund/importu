module FixturesHelper
  def infile(name, ext)
    File.join(fixtures_path, name, "infile.#{ext}")
  end

  def expected_model_json(name)
    load_fixture_json(name, "model.json")
  end

  def expected_record_json(name)
    load_fixture_json(name, "record.json")
  end

  def expected_record_json!(name, records)
    # Dump and re-parse to ensure everything is JSON types w/ string keys
    record_json = JSON.parse(JSON.dump(records.map(&:to_hash)))
    expect(record_json).to eq expected_record_json("books1")
  end

  def expected_summary_json(name)
    load_fixture_json(name, "summary.json")
  end

  def expected_summary_json!(name, summary)
    summary_json = JSON.parse(JSON.dump(summary.to_hash))
    expect(summary_json).to eq expected_summary_json(name)
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
