module FixturesHelper
  def infile(name, ext)
    File.join(fixtures_path, name, "infile.#{ext}")
  end

  def expected_model_json(name)
    @expected_model ||= Hash.new do |hash, name|
      data = File.read(File.join(fixtures_path, name, "model.json"))
      JSON.parse(data)
    end

    @expected_model[name]
  end

  def fixtures_path
    File.expand_path("../../fixtures", __FILE__)
  end

end
