require "spec_helper"

require "importu/converter_context"
require "importu/converters"
require "importu/definition"

RSpec.describe "Importu Converters" do
  subject(:context) { Importu::ConverterContext.with_config(definition.config).new(data) }
  let(:data) { { "field1" => " value1 ", "field2" => "value2" } }

  let(:definition) do
    Class.new do
      extend Importu::Definition
      include Importu::Converters
    end
  end

  describe ":raw converter" do
    let(:definition) { Class.new(super()) { fields :field1, :field3 } }
    let(:data) { { "field1" => " value1 ", "field2" => "value2" } }

    it "uses definition's label as key when looking up data" do
      expect(context.raw(:field1)).to eq " value1 "
    end

    it "raises an exception if field definition is not defined" do
      expect { context.raw(:field2) }.to raise_error(Importu::InvalidDefinition)
    end
  end

  describe ":trimmed converter" do
    it "returns nil if raw value is nil" do
      allow(context).to receive(:raw_value).and_return(nil)
      expect(context.trimmed(:field1)).to be nil
    end

    it "returns nil if a blank string" do
      allow(context).to receive(:raw_value).and_return("")
      expect(context.trimmed(:field1)).to be nil
    end

    it "returns stripped value if a string" do
      allow(context).to receive(:raw_value).and_return("  abc  123 ")
      expect(context.trimmed(:field1)).to eq "abc  123"
    end

    it "returns original value if not a string" do
      raw_val = Time.now
      allow(context).to receive(:raw_value).and_return(raw_val)
      expect(context.trimmed(:field1)).to eq raw_val
    end
  end

  describe ":string converter" do
    it "returns nil if trimmed value is nil" do
      definition.converter(:trimmed) {|*| nil }
      expect(context.string(:field1)).to be nil
    end

    it "returns string if trimmed value is a string" do
      definition.converter(:trimmed) {|*| "six pence" }
      expect(context.string(:field1)).to eq "six pence"
    end

    it "converts trimmed value to string if not a string" do
      trimmed_val = Time.now
      definition.converter(:trimmed) {|*| trimmed_val }
      expect(context.string(:field1)).to eq trimmed_val.to_s
    end
  end

  describe ":integer converter" do
    it "returns nil if trimmed value is nil" do
      definition.converter(:trimmed) {|*| nil }
      expect(context.integer(:field1)).to be nil
    end

    it "returns integer if trimmed value returns an integer" do
      definition.converter(:trimmed) {|*| 92 }
      expect(context.integer(:field1)).to eq 92
    end

    it "converts trimmed value to integer if not an integer type" do
      definition.converter(:trimmed) {|*| "29" }
      expect(context.integer(:field1)).to eq 29
    end

    it "handles values with a leading 0 as a decimal (not octal)" do
      definition.converter(:trimmed) {|*| "044" }
      expect(context.integer(:field1)).to eq 44
    end

    it "raises an ArgumentError if trimmed value is not a valid integer" do
      definition.converter(:trimmed) {|*| "4.25" }
      expect { context.integer(:field1) }.to raise_error(ArgumentError)
    end
  end

  describe ":float converter" do
    it "returns nil if trimmed value is nil" do
      definition.converter(:trimmed) {|*| nil }
      expect(context.float(:field1)).to be nil
    end

    it "returns float if trimmed value returns an float" do
      definition.converter(:trimmed) {|*| 92.25 }
      expect(context.float(:field1)).to eq 92.25
    end

    it "converts trimmed value to float if not an float type" do
      definition.converter(:trimmed) {|*| "29.4" }
      expect(context.float(:field1)).to eq 29.4
    end

    it "converts whole values to float" do
      definition.converter(:trimmed) {|*| "77" }
      expect(context.float(:field1)).to eq 77.0
    end

    it "raises an ArgumentError if trimmed value is not a valid float" do
      definition.converter(:trimmed) {|*| "4d6point3" }
      expect { context.float(:field1) }.to raise_error(ArgumentError)
    end
  end

  describe ":decimal converter" do
    it "returns nil if trimmed value is nil" do
      definition.converter(:trimmed) {|*| nil }
      expect(context.decimal(:field1)).to be nil
    end

    it "returns decimal if trimmed value returns an decimal" do
      trimmed_val = BigDecimal("92.25")
      definition.converter(:trimmed) {|*| trimmed_val }
      expect(context.decimal(:field1)).to eq trimmed_val
    end

    it "converts trimmed value to decimal if not an decimal type" do
      definition.converter(:trimmed) {|*| "29.4" }
      expect(context.decimal(:field1)).to eq BigDecimal("29.4")
    end

    it "converts whole values to decimal" do
      definition.converter(:trimmed) {|*| "77" }
      expect(context.decimal(:field1)).to eq BigDecimal("77.0")
    end

    it "raises an ArgumentError if trimmed value is not a valid decimal" do
      definition.converter(:trimmed) {|*| "4d6point3" }
      expect { context.decimal(:field1) }.to raise_error(ArgumentError)
    end
  end

  describe ":boolean converter" do
    it "returns nil if trimmed value is nil" do
      definition.converter(:trimmed) {|*| nil }
      expect(context.boolean(:field1)).to be nil
    end

    it "returns true if trimmed value is true" do
      definition.converter(:trimmed) {|*| true }
      expect(context.boolean(:field1)).to eq true
    end

    it "returns true if trimmed value is 'true'" do
      definition.converter(:trimmed) {|*| "true" }
      expect(context.boolean(:field1)).to eq true
    end

    it "returns true if trimmed value is 'yes'" do
      definition.converter(:trimmed) {|*| "yes" }
      expect(context.boolean(:field1)).to eq true
    end

    it "returns true if trimmed value is '1'" do
      definition.converter(:trimmed) {|*| "1" }
      expect(context.boolean(:field1)).to eq true
    end

    it "returns true if trimmed value is 1" do
      definition.converter(:trimmed) {|*| 1 }
      expect(context.boolean(:field1)).to eq true
    end

    it "returns false if trimmed value is false" do
      definition.converter(:trimmed) {|*| false }
      expect(context.boolean(:field1)).to eq false
    end

    it "returns false if trimmed value is 'false'" do
      definition.converter(:trimmed) {|*| "false" }
      expect(context.boolean(:field1)).to eq false
    end

    it "returns false if trimmed value is 'no'" do
      definition.converter(:trimmed) {|*| "no" }
      expect(context.boolean(:field1)).to eq false
    end

    it "returns false if trimmed value is '0'" do
      definition.converter(:trimmed) {|*| "0" }
      expect(context.boolean(:field1)).to eq false
    end

    it "returns false if trimmed value is 0" do
      definition.converter(:trimmed) {|*| 0 }
      expect(context.boolean(:field1)).to eq false
    end

    it "raises an ArgumentError if the value is invalid" do
      definition.converter(:trimmed) {|*| "why-not-both" }
      expect { context.boolean(:field1) }.to raise_error(ArgumentError)
    end

    it "treats values as case-insensitive" do
      definition.converter(:trimmed) {|*| "TrUE" }
      expect(context.boolean(:field1)).to eq true
    end
  end

  describe ":date converter" do
    it "returns nil if trimmed value is nil" do
      definition.converter(:trimmed) {|*| nil }
      expect(context.date(:field1)).to be nil
    end

    context "when a format is not specified" do
      it "tries to guess the date format (DD/MM/YYYY is default?)" do
        expected = Date.new(2012, 10, 3)
        definition.converter(:trimmed) {|*| "03/10/2012" }
        expect(context.date(:field1)).to eq expected
      end

      it "raises an ArgumentError if the date is invaild" do
        definition.converter(:trimmed) {|*| "2012-04-32" }
        expect { context.date(:field1) }.to raise_error(ArgumentError)
      end
    end

    context "when a format is specified" do
      it "parses dates that match the format" do
        expected = Date.new(2012, 4, 18)
        definition.converter(:trimmed) {|*| "04/18/2012" }
        expect(context.date(:field1, format: "%m/%d/%Y")).to eq expected
      end

      it "raises an ArgumentError if date doesn't match the format" do
        definition.converter(:trimmed) {|*| "04-18-2012" }
        expect { context.date(:field1) }.to raise_error(ArgumentError)
      end

      it "raises an ArgumentError if the date is invalid" do
        definition.converter(:trimmed) {|*| "04/32/2012" }
        expect { context.date(:field1) }.to raise_error(ArgumentError)
      end
    end
  end

  describe ":datetime converter" do
    it "returns nil if trimmed value is nil" do
      definition.converter(:trimmed) {|*| nil }
      expect(context.datetime(:field1)).to be nil
    end

    context "when a format is not specified" do
      it "tries to guess the date format (DD/MM/YYYY is default?)" do
        expected = Time.parse("2012-10-03 04:37:29Z")
        definition.converter(:trimmed) {|*| "03/10/2012 04:37:29" }
        expect(context.datetime(:field1)).to eq expected
      end

      it "raises an ArgumentError if the datetime is invaild" do
        definition.converter(:trimmed) {|*| "2012-04-32 15:41:22" }
        expect { context.datetime(:field1) }.to raise_error(ArgumentError)
      end
    end

    context "when a format is specified" do
      it "parses datetimes that match the format" do
        expected = Time.parse("2012-04-18 16:37:00Z")
        definition.converter(:trimmed) {|*| "04/18/2012 16:37" }
        expect(context.datetime(:field1, format: "%m/%d/%Y %H:%M")).to eq expected
      end

      it "raises an ArgumentError if datetime doesn't match the format" do
        definition.converter(:trimmed) {|*| "04-18-2012 15:22:19" }
        expect { context.datetime(:field1) }.to raise_error(ArgumentError)
      end

      it "raises an ArgumentError if the datetime is invalid" do
        definition.converter(:trimmed) {|*| "04/32/2012 00:00:00" }
        expect { context.datetime(:field1) }.to raise_error(ArgumentError)
      end
    end
  end

end
