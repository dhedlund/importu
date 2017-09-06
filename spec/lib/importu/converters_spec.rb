require "spec_helper"

require "importu/converters"
require "importu/definition"
require "importu/record"

RSpec.describe "Importu Converters" do
  subject(:record) { Importu::Record.new({}, {}, definition.config) }
  let(:definition) do
    Class.new do
      extend Importu::Definition
      include Importu::Converters
    end
  end

  describe ":raw converter" do
    it "uses definition's label as key when looking up data" do
      allow(record).to receive(:field_definitions).and_return({ field1: { label: "field1", required: true } })
      allow(record).to receive(:data).and_return({ "field1" => " value1 ", "field2" => "value2" })
      expect(record.convert(:field1, :raw)).to eq " value1 "
    end

    it "raises an exception if field definition is not defined" do
      expect { record.convert(:field1, :raw) }.to raise_error(Importu::InvalidDefinition)
    end

    it "raises MissingField if field data not defined" do
      allow(record).to receive(:field_definitions).and_return({ field1: { required: true } })
      expect { record.convert(:field1, :raw) }.to raise_error(Importu::MissingField)
    end
  end

  describe ":clean converter" do
    it "returns nil if raw data is nil" do
      definition.converter(:raw) { nil }
      expect(record.convert(:field1, :raw)).to be nil
    end

    it "returns nil if a blank string" do
      definition.converter(:raw) { "" }
      expect(record.convert(:field1, :clean)).to be nil
    end

    it "returns stripped value if a string" do
      definition.converter(:raw) { "  abc  123 " }
      expect(record.convert(:field1, :clean)).to eq "abc  123"
    end

    it "returns original value if not a string" do
      raw_val = Time.now
      definition.converter(:raw) { raw_val }
      expect(record.convert(:field1, :clean)).to eq raw_val
    end
  end

  describe ":string converter" do
    it "returns nil if clean value is nil" do
      definition.converter(:clean) { nil }
      expect(record.convert(:field1, :string)).to be nil
    end

    it "returns string if clean value is a string" do
      definition.converter(:clean) { "six pence" }
      expect(record.convert(:field1, :string)).to eq "six pence"
    end

    it "converts clean value to string if not a string" do
      clean_val = Time.now
      definition.converter(:clean) { clean_val }
      expect(record.convert(:field1, :string)).to eq clean_val.to_s
    end
  end

  describe ":integer converter" do
    it "returns nil if clean value is nil" do
      definition.converter(:clean) { nil }
      expect(record.convert(:field1, :integer)).to be nil
    end

    it "returns integer if clean value returns an integer" do
      definition.converter(:clean) { 92 }
      expect(record.convert(:field1, :integer)).to eq 92
    end

    it "converts clean value to integer if not an integer type" do
      definition.converter(:clean) { "29" }
      expect(record.convert(:field1, :integer)).to eq 29
    end

    it "handles values with a leading 0 as a decimal (not octal)" do
      definition.converter(:clean) { "044" }
      expect(record.convert(:field1, :integer)).to eq 44
    end

    it "raises an exception if clean value is not a valid integer" do
      definition.converter(:clean) { "4.25" }
      expect { record.convert(:field1, :integer) }.to raise_error(Importu::FieldParseError)
    end
  end

  describe ":float converter" do
    it "returns nil if clean value is nil" do
      definition.converter(:clean) { nil }
      expect(record.convert(:field1, :float)).to be nil
    end

    it "returns float if clean value returns an float" do
      definition.converter(:clean) { 92.25 }
      expect(record.convert(:field1, :float)).to eq 92.25
    end

    it "converts clean value to float if not an float type" do
      definition.converter(:clean) { "29.4" }
      expect(record.convert(:field1, :float)).to eq 29.4
    end

    it "converts whole values to float" do
      definition.converter(:clean) { "77" }
      expect(record.convert(:field1, :float)).to eq 77.0
    end

    it "raises an exception if clean value is not a valid float" do
      definition.converter(:clean) { "4d6point3" }
      expect { record.convert(:field1, :float) }.to raise_error(Importu::FieldParseError)
    end
  end

  describe ":decimal converter" do
    it "returns nil if clean value is nil" do
      definition.converter(:clean) { nil }
      expect(record.convert(:field1, :decimal)).to be nil
    end

    it "returns decimal if clean value returns an decimal" do
      clean_val = BigDecimal("92.25")
      definition.converter(:clean) { clean_val }
      expect(record.convert(:field1, :decimal)).to eq clean_val
    end

    it "converts clean value to decimal if not an decimal type" do
      definition.converter(:clean) { "29.4" }
      expect(record.convert(:field1, :decimal)).to eq BigDecimal("29.4")
    end

    it "converts whole values to decimal" do
      definition.converter(:clean) { "77" }
      expect(record.convert(:field1, :decimal)).to eq BigDecimal("77.0")
    end

    it "raises an exception if clean value is not a valid decimal" do
      definition.converter(:clean) { "4d6point3" }
      expect { record.convert(:field1, :decimal) }.to raise_error(Importu::FieldParseError)
    end
  end

  describe ":boolean converter" do
    it "returns nil if clean value is nil" do
      definition.converter(:clean) { nil }
      expect(record.convert(:field1, :boolean)).to be nil
    end

    it "returns true if clean value is true" do
      definition.converter(:clean) { true }
      expect(record.convert(:field1, :boolean)).to eq true
    end

    it "returns true if clean value is 'true'" do
      definition.converter(:clean) { "true" }
      expect(record.convert(:field1, :boolean)).to eq true
    end

    it "returns true if clean value is 'yes'" do
      definition.converter(:clean) { "yes" }
      expect(record.convert(:field1, :boolean)).to eq true
    end

    it "returns true if clean value is '1'" do
      definition.converter(:clean) { "1" }
      expect(record.convert(:field1, :boolean)).to eq true
    end

    it "returns true if clean value is 1" do
      definition.converter(:clean) { 1 }
      expect(record.convert(:field1, :boolean)).to eq true
    end

    it "returns false if clean value is false" do
      definition.converter(:clean) { false }
      expect(record.convert(:field1, :boolean)).to eq false
    end

    it "returns false if clean value is 'false'" do
      definition.converter(:clean) { "false" }
      expect(record.convert(:field1, :boolean)).to eq false
    end

    it "returns false if clean value is 'no'" do
      definition.converter(:clean) { "no" }
      expect(record.convert(:field1, :boolean)).to eq false
    end

    it "returns false if clean value is '0'" do
      definition.converter(:clean) { "0" }
      expect(record.convert(:field1, :boolean)).to eq false
    end

    it "returns false if clean value is 0" do
      definition.converter(:clean) { 0 }
      expect(record.convert(:field1, :boolean)).to eq false
    end

    it "raises an exception if the value is invalid" do
      definition.converter(:clean) { "why-not-both" }
      expect { record.convert(:field1, :boolean) }.to raise_error(Importu::FieldParseError)
    end

    it "treats values as case-insensitive" do
      definition.converter(:clean) { "TrUE" }
      expect(record.convert(:field1, :boolean)).to eq true
    end
  end

  describe ":date converter" do
    it "returns nil if clean value is nil" do
      definition.converter(:clean) { nil }
      expect(record.convert(:field1, :date)).to be nil
    end

    context "when a format is not specified" do
      it "tries to guess the date format (DD/MM/YYYY is default?)" do
        expected = Date.new(2012, 10, 3)
        definition.converter(:clean) { "03/10/2012" }
        expect(record.convert(:field1, :date)).to eq expected
      end

      it "raises an exception if the date is invaild" do
        definition.converter(:clean) { "2012-04-32" }
        expect { record.convert(:field1, :date) }.to raise_error(Importu::FieldParseError)
      end
    end

    context "when a format is specified" do
      it "parses dates that match the format" do
        expected = Date.new(2012, 4, 18)
        definition.converter(:clean) { "04/18/2012" }
        expect(record.convert(:field1, :date, format: "%m/%d/%Y")).to eq expected
      end

      it "raises exception if date doesn't match the format" do
        definition.converter(:clean) { "04-18-2012" }
        expect { record.convert(:field1, :date) }.to raise_error(Importu::FieldParseError)
      end

      it "raises an exception if the date is invalid" do
        definition.converter(:clean) { "04/32/2012" }
        expect { record.convert(:field1, :date) }.to raise_error(Importu::FieldParseError)
      end
    end
  end

  describe ":datetime converter" do
    it "returns nil if clean value is nil" do
      definition.converter(:clean) { nil }
      expect(record.convert(:field1, :datetime)).to be nil
    end

    context "when a format is not specified" do
      it "tries to guess the date format (DD/MM/YYYY is default?)" do
        expected = Time.parse("2012-10-03 04:37:29Z")
        definition.converter(:clean) { "03/10/2012 04:37:29" }
        expect(record.convert(:field1, :datetime)).to eq expected
      end

      it "raises an exception if the datetime is invaild" do
        definition.converter(:clean) { "2012-04-32 15:41:22" }
        expect { record.convert(:field1, :datetime) }.to raise_error(Importu::FieldParseError)
      end
    end

    context "when a format is specified" do
      it "parses datetimes that match the format" do
        expected = Time.parse("2012-04-18 16:37:00Z")
        definition.converter(:clean) { "04/18/2012 16:37" }
        expect(record.convert(:field1, :datetime, format: "%m/%d/%Y %H:%M")).to eq expected
      end

      it "raises exception if datetime doesn't match the format" do
        definition.converter(:clean) { "04-18-2012 15:22:19" }
        expect { record.convert(:field1, :datetime) }.to raise_error(Importu::FieldParseError)
      end

      it "raises an exception if the datetime is invalid" do
        definition.converter(:clean) { "04/32/2012 00:00:00" }
        expect { record.convert(:field1, :datetime) }.to raise_error(Importu::FieldParseError)
      end
    end
  end

end
