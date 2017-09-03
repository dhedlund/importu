module FixturesHelper
  def csv_infile(name)
    File.join(fixtures_path, "#{name}.csv")
  end

  def fixtures_path
    File.expand_path("../../fixtures", __FILE__)
  end

end
