require 'spec_helper'

require 'active_support/core_ext/time/calculations'

describe Importu::Importer do
  subject(:record) { build(:importer_record) }

  describe ":raw converter" do
    it "uses definition's label as key when looking up data" do
      record.stub(:definitions => { :field1 => { :label => "field1", :required => true } })
      record.stub(:data => { "field1" => " value1 ", "field2" => "value2" })
      record.convert(:field1, :raw).should eq " value1 "
    end

    it "raises an exception if field definition is not defined" do
      expect { record.convert(:field1, :raw) }.to raise_error(Importu::InvalidDefinition)
    end

    it "raises MissingField if field data not defined" do
      record.stub(:definitions => { :field1 => { :required => true } })
      expect { record.convert(:field1, :raw) }.to raise_error(Importu::MissingField)
    end
  end

  describe ":clean converter" do
    it "returns nil if raw data is nil" do
      record.converters[:raw] = proc { nil }
      record.convert(:field1, :clean).should be nil
    end

    it "returns nil if a blank string" do
      record.converters[:raw] = proc { "" }
      record.convert(:field1, :clean).should be nil
    end

    it "returns stripped value if a string" do
      record.converters[:raw] = proc { "  abc  123 " }
      record.convert(:field1, :clean).should eq "abc  123"
    end

    it "returns original value if not a string" do
      raw_val = Time.now
      record.converters[:raw] = proc { raw_val }
      record.convert(:field1, :clean).should eq raw_val
    end
  end

  describe ":string converter" do
    it "returns nil if clean value is nil" do
      record.converters[:clean] = proc { nil }
      record.convert(:field1, :string).should be nil
    end

    it "returns string if clean value is a string" do
      record.converters[:clean] = proc { "six pence" }
      record.convert(:field1, :string).should eq "six pence"
    end

    it "converts clean value to string if not a string" do
      clean_val = Time.now
      record.converters[:clean] = proc { clean_val }
      record.convert(:field1, :string).should eq clean_val.to_s
    end
  end

  describe ":integer converter" do
    it "returns nil if clean value is nil" do
      record.converters[:clean] = proc { nil }
      record.convert(:field1, :integer).should be nil
    end

    it "returns integer if clean value returns an integer" do
      record.converters[:clean] = proc { 92 }
      record.convert(:field1, :integer).should eq 92
    end

    it "converts clean value to integer if not an integer type" do
      record.converters[:clean] = proc { "29" }
      record.convert(:field1, :integer).should eq 29
    end

    it "raises an exception if clean value is not a valid integer" do
      record.converters[:clean] = proc { "4.25" }
      expect { record.convert(:field1, :integer) }.to raise_error(Importu::FieldParseError)
    end
  end

  describe ":float converter" do
    it "returns nil if clean value is nil" do
      record.converters[:clean] = proc { nil }
      record.convert(:field1, :float).should be nil
    end

    it "returns float if clean value returns an float" do
      record.converters[:clean] = proc { 92.25 }
      record.convert(:field1, :float).should eq 92.25
    end

    it "converts clean value to float if not an float type" do
      record.converters[:clean] = proc { "29.4" }
      record.convert(:field1, :float).should eq 29.4
    end

    it "converts whole values to float" do
      record.converters[:clean] = proc { "77" }
      record.convert(:field1, :float).should eq 77.0
    end

    it "raises an exception if clean value is not a valid float" do
      record.converters[:clean] = proc { "4d6point3" }
      expect { record.convert(:field1, :float) }.to raise_error(Importu::FieldParseError)
    end
  end

  describe ":decimal converter" do
    it "returns nil if clean value is nil" do
      record.converters[:clean] = proc { nil }
      record.convert(:field1, :decimal).should be nil
    end

    it "returns decimal if clean value returns an decimal" do
      clean_val = BigDecimal("92.25")
      record.converters[:clean] = proc { clean_val }
      record.convert(:field1, :decimal).should eq clean_val
    end

    it "converts clean value to decimal if not an decimal type" do
      record.converters[:clean] = proc { "29.4" }
      record.convert(:field1, :decimal).should eq BigDecimal("29.4")
    end

    it "converts whole values to decimal" do
      record.converters[:clean] = proc { "77" }
      record.convert(:field1, :decimal).should eq BigDecimal("77.0")
    end

    it "raises an exception if clean value is not a valid decimal" do
      record.converters[:clean] = proc { "4d6point3" }
      expect { record.convert(:field1, :decimal) }.to raise_error(Importu::FieldParseError)
    end
  end

  describe ":boolean converter" do
    it "returns nil if clean value is nil" do
      record.converters[:clean] = proc { nil }
      record.convert(:field1, :boolean).should be nil
    end

    it "returns true if clean value is true" do
      record.converters[:clean] = proc { true }
      record.convert(:field1, :boolean).should eq true
    end

    it "returns true if clean value is 'true'" do
      record.converters[:clean] = proc { "true" }
      record.convert(:field1, :boolean).should eq true
    end

    it "returns true if clean value is 'yes'" do
      record.converters[:clean] = proc { "yes" }
      record.convert(:field1, :boolean).should eq true
    end

    it "returns true if clean value is '1'" do
      record.converters[:clean] = proc { "1" }
      record.convert(:field1, :boolean).should eq true
    end

    it "returns true if clean value is 1" do
      record.converters[:clean] = proc { 1 }
      record.convert(:field1, :boolean).should eq true
    end

    it "returns false if clean value is false" do
      record.converters[:clean] = proc { false }
      record.convert(:field1, :boolean).should eq false
    end

    it "returns false if clean value is 'false'" do
      record.converters[:clean] = proc { "false" }
      record.convert(:field1, :boolean).should eq false
    end

    it "returns false if clean value is 'no'" do
      record.converters[:clean] = proc { "no" }
      record.convert(:field1, :boolean).should eq false
    end

    it "returns false if clean value is '0'" do
      record.converters[:clean] = proc { "0" }
      record.convert(:field1, :boolean).should eq false
    end

    it "returns false if clean value is 0" do
      record.converters[:clean] = proc { 0 }
      record.convert(:field1, :boolean).should eq false
    end
  end

  describe ":date converter" do
    it "returns nil if clean value is nil" do
      record.converters[:clean] = proc { nil }
      record.convert(:field1, :date).should be nil
    end

    context "when a format is not specified" do
      it "tries to guess the date format (DD/MM/YYYY is default?)" do
        expected = Date.new(2012, 10, 3)
        record.converters[:clean] = proc { "03/10/2012" }
        record.convert(:field1, :date).should eq expected
      end

      it "raises an exception if the date is invaild" do
        record.converters[:clean] = proc { "2012-04-32" }
        expect { record.convert(:field1, :date) }.to raise_error(Importu::FieldParseError)
      end
    end

    context "when a format is specified" do
      it "parses dates that match the format" do
        expected = Date.new(2012, 4, 18)
        record.converters[:clean] = proc { "04/18/2012" }
        record.convert(:field1, :date, :format => "%m/%d/%Y").should eq expected
      end

      it "raises exception if date doesn't match the format" do
        record.converters[:clean] = proc { "04-18-2012" }
        expect { record.convert(:field1, :date) }.to raise_error(Importu::FieldParseError)
      end

      it "raises an exception if the date is invalid" do
        record.converters[:clean] = proc { "04/32/2012" }
        expect { record.convert(:field1, :date) }.to raise_error(Importu::FieldParseError)
      end
    end
  end

  describe ":datetime converter" do
    it "returns nil if clean value is nil" do
      record.converters[:clean] = proc { nil }
      record.convert(:field1, :datetime).should be nil
    end

    context "when a format is not specified" do
      it "tries to guess the date format (DD/MM/YYYY is default?)" do
        expected = DateTime.parse("2012-10-03 04:37:29")
        record.converters[:clean] = proc { "03/10/2012 04:37:29" }
        record.convert(:field1, :datetime).should eq expected
      end

      it "raises an exception if the datetime is invaild" do
        record.converters[:clean] = proc { "2012-04-32 15:41:22" }
        expect { record.convert(:field1, :datetime) }.to raise_error(Importu::FieldParseError)
      end
    end

    context "when a format is specified" do
      it "parses datetimes that match the format" do
        expected = DateTime.parse("2012-04-18 16:37:00")
        record.converters[:clean] = proc { "04/18/2012 16:37" }
        record.convert(:field1, :datetime, :format => "%m/%d/%Y %H:%M").should eq expected
      end

      it "raises exception if datetime doesn't match the format" do
        record.converters[:clean] = proc { "04-18-2012 15:22:19" }
        expect { record.convert(:field1, :datetime) }.to raise_error(Importu::FieldParseError)
      end

      it "raises an exception if the datetime is invalid" do
        record.converters[:clean] = proc { "04/32/2012 00:00:00" }
        expect { record.convert(:field1, :datetime) }.to raise_error(Importu::FieldParseError)
      end
    end
  end

end
