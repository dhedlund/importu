require 'spec_helper'

require 'active_support/core_ext/time/calculations'

describe Importu::Importer do
  let(:data) { Hash.new }
  let(:definition) { Hash.new }

  describe ":raw converter" do
    it "uses definition's label as key when looking up data" do
      definition = { :label => "field1" }
      data = { "field1" => " value1 ", "field2" => "value2" }
      Importu::Importer.raw(data, definition).should eq " value1 "
    end

    it "raises an exception if field definition is not defined" do
      expect { Importu::Importer.raw({}, {}) }.to raise_error
    end

    it "raises MissingField if field data not defined" do
      definition = { :label => "field1" }
      expect { Importu::Importer.raw({}, definition) }.to raise_error(Importu::MissingField)
    end
  end

  describe ":clean converter" do
    it "starts with the raw field value" do
      Importu::Importer.should_receive(:raw).and_return("value1")
      Importu::Importer.clean(data, definition)
    end

    it "returns nil if raw data is nil" do
      Importu::Importer.should_receive(:raw).and_return(nil)
      Importu::Importer.clean(data, definition).should be nil
    end

    it "returns nil if a blank string" do
      Importu::Importer.should_receive(:raw).and_return("    ")
      Importu::Importer.clean(data, definition).should be nil
    end

    it "returns stripped value if a string" do
      Importu::Importer.should_receive(:raw).and_return("  abc  123 ")
      Importu::Importer.clean(data, definition).should eq "abc  123"
    end
 
    it "returns original value if not a string" do
      raw_val = Time.now
      Importu::Importer.should_receive(:raw).and_return(raw_val)
      Importu::Importer.clean(data, definition).should eq raw_val
    end
  end

  describe ":string converter" do
    it "starts with the clean field value" do
      Importu::Importer.should_receive(:clean).and_return("value1")
      Importu::Importer.string(data, definition)
    end

    it "returns nil if clean value is nil" do
      Importu::Importer.should_receive(:clean).and_return(nil)
      Importu::Importer.string(data, definition).should be nil
    end

    it "returns string if clean value is a string" do
      Importu::Importer.should_receive(:clean).and_return("six pence")
      Importu::Importer.string(data, definition).should eq "six pence"
    end

    it "converts clean value to string if not a string" do
      clean_val = Time.now
      Importu::Importer.should_receive(:clean).and_return(clean_val)
      Importu::Importer.string(data, definition).should eq clean_val.to_s
    end
  end

  describe ":integer converter" do
    it "starts with the clean field value" do
      Importu::Importer.should_receive(:clean).and_return("74")
      Importu::Importer.integer(data, definition)
    end

    it "returns nil if clean value is nil" do
      Importu::Importer.should_receive(:clean).and_return(nil)
      Importu::Importer.integer(data, definition).should be nil
    end

    it "returns integer if clean value returns an integer" do
      Importu::Importer.should_receive(:clean).and_return(92)
      Importu::Importer.integer(data, definition).should eq 92
    end

    it "converts clean value to integer if not an integer type" do
      Importu::Importer.should_receive(:clean).and_return("29")
      Importu::Importer.integer(data, definition).should eq 29
    end

    it "raises an exception if clean value is not a valid integer" do
      Importu::Importer.should_receive(:clean).and_return("4.25")
      expect { Importu::Importer.integer(data, definition) }.to raise_error(ArgumentError)
    end
  end

  describe ":float converter" do
    it "starts with the clean field value" do
      Importu::Importer.should_receive(:clean).and_return("74.6")
      Importu::Importer.float(data, definition)
    end

    it "returns nil if clean value is nil" do
      Importu::Importer.should_receive(:clean).and_return(nil)
      Importu::Importer.float(data, definition).should be nil
    end

    it "returns float if clean value returns an float" do
      Importu::Importer.should_receive(:clean).and_return(92.25)
      Importu::Importer.float(data, definition).should eq 92.25
    end

    it "converts clean value to float if not an float type" do
      Importu::Importer.should_receive(:clean).and_return("29.4")
      Importu::Importer.float(data, definition).should eq 29.4
    end

    it "converts whole values to float" do
      Importu::Importer.should_receive(:clean).and_return("77")
      Importu::Importer.float(data, definition).should eq 77.0
    end

    it "raises an exception if clean value is not a valid float" do
      Importu::Importer.should_receive(:clean).and_return("4d6point3")
      expect { Importu::Importer.float(data, definition) }.to raise_error(ArgumentError)
    end
  end

  describe ":decimal converter" do
    it "starts with the clean field value" do
      Importu::Importer.should_receive(:clean).and_return("74.6")
      Importu::Importer.decimal(data, definition)
    end

    it "returns nil if clean value is nil" do
      Importu::Importer.should_receive(:clean).and_return(nil)
      Importu::Importer.decimal(data, definition).should be nil
    end

    it "returns decimal if clean value returns an decimal" do
      clean_val = BigDecimal("92.25")
      Importu::Importer.should_receive(:clean).and_return(clean_val)
      Importu::Importer.decimal(data, definition).should eq clean_val
    end

    it "converts clean value to decimal if not an decimal type" do
      Importu::Importer.should_receive(:clean).and_return("29.4")
      Importu::Importer.decimal(data, definition).should eq BigDecimal("29.4")
    end

    it "converts whole values to decimal" do
      Importu::Importer.should_receive(:clean).and_return("77")
      Importu::Importer.decimal(data, definition).should eq BigDecimal("77.0")
    end

    it "raises an exception if clean value is not a valid decimal" do
      Importu::Importer.should_receive(:clean).and_return("4d6point3")
      expect { Importu::Importer.decimal(data, definition) }.to raise_error(ArgumentError)
    end
  end

  describe ":boolean converter" do
    it "starts with the clean field value" do
      Importu::Importer.should_receive(:clean).and_return(true)
      Importu::Importer.boolean(data, definition)
    end

    it "returns nil if clean value is nil" do
      Importu::Importer.should_receive(:clean).and_return(nil)
      Importu::Importer.boolean(data, definition).should be nil
    end

    it "returns true if clean value is true" do
      Importu::Importer.should_receive(:clean).and_return(true)
      Importu::Importer.boolean(data, definition).should eq true
    end

    it "returns true if clean value is 'true'" do
      Importu::Importer.should_receive(:clean).and_return("true")
      Importu::Importer.boolean(data, definition).should eq true
    end

    it "returns true if clean value is 'yes'" do
      Importu::Importer.should_receive(:clean).and_return("yes")
      Importu::Importer.boolean(data, definition).should eq true
    end

    it "returns true if clean value is '1'" do
      Importu::Importer.should_receive(:clean).and_return("1")
      Importu::Importer.boolean(data, definition).should eq true
    end

    it "returns true if clean value is 1" do
      Importu::Importer.should_receive(:clean).and_return(1)
      Importu::Importer.boolean(data, definition).should eq true
    end

    it "returns false if clean value is false" do
      Importu::Importer.should_receive(:clean).and_return(false)
      Importu::Importer.boolean(data, definition).should eq false
    end

    it "returns false if clean value is 'false'" do
      Importu::Importer.should_receive(:clean).and_return("false")
      Importu::Importer.boolean(data, definition).should eq false
    end

    it "returns false if clean value is 'no'" do
      Importu::Importer.should_receive(:clean).and_return("no")
      Importu::Importer.boolean(data, definition).should eq false
    end

    it "returns false if clean value is '0'" do
      Importu::Importer.should_receive(:clean).and_return("0")
      Importu::Importer.boolean(data, definition).should eq false
    end

    it "returns false if clean value is 0" do
      Importu::Importer.should_receive(:clean).and_return(0)
      Importu::Importer.boolean(data, definition).should eq false
    end
  end

  describe ":date converter" do
    it "starts with the clean field value" do
      Importu::Importer.should_receive(:clean).and_return("2012-01-01")
      Importu::Importer.date(data, definition)
    end

    it "returns nil if clean value is nil" do
      Importu::Importer.should_receive(:clean).and_return(nil)
      Importu::Importer.date(data, definition).should be nil
    end

    context "when a date_format is not specified" do
      it "tries to guess the date format (DD/MM/YYYY is default?)" do
        Importu::Importer.should_receive(:clean).and_return("03/10/2012")
        Importu::Importer.date(data, definition).should eq Date.new(2012, 10, 3)
      end

      it "raises an exception if the date is invaild" do
        Importu::Importer.should_receive(:clean).and_return("2012-04-32")
        expect { Importu::Importer.date(data, definition) }.to raise_error(ArgumentError)
      end
    end

    context "when a date_format is specified" do
      let(:definition) { { :date_format => "%m/%d/%Y" } }

      it "parses dates that match the format" do
        Importu::Importer.should_receive(:clean).and_return("04/18/2012")
        Importu::Importer.date(data, definition).should eq Date.new(2012, 4, 18)
      end

      it "raises exception if date doesn't match the format" do
        Importu::Importer.should_receive(:clean).and_return("04-18-2012")
        expect { Importu::Importer.date(data, definition) }.to raise_error(ArgumentError)
      end

      it "raises an exception if the date is invalid" do
        Importu::Importer.should_receive(:clean).and_return("04/32/2012")
        expect { Importu::Importer.date(data, definition) }.to raise_error(ArgumentError)
      end
    end
  end

  describe ":datetime converter" do
    it "starts with the clean field value" do
      Importu::Importer.should_receive(:clean).and_return("2012-01-01 04:37:29")
      Importu::Importer.datetime(data, definition)
    end

    it "returns nil if clean value is nil" do
      Importu::Importer.should_receive(:clean).and_return(nil)
      Importu::Importer.datetime(data, definition).should be nil
    end

    context "when a date_format is not specified" do
      it "tries to guess the date format (DD/MM/YYYY is default?)" do
        Importu::Importer.should_receive(:clean).and_return("03/10/2012 04:37:29")
        Importu::Importer.datetime(data, definition).should eq DateTime.parse("2012-10-03 04:37:29")
      end

      it "raises an exception if the datetime is invaild" do
        Importu::Importer.should_receive(:clean).and_return("2012-04-32 15:41:22")
        expect { Importu::Importer.datetime(data, definition) }.to raise_error(ArgumentError)
      end
    end

    context "when a date_format is specified" do
      let(:definition) { { :date_format => "%m/%d/%Y %H:%M" } }

      it "parses datetimes that match the format" do
        Importu::Importer.should_receive(:clean).and_return("04/18/2012 16:37")
        Importu::Importer.datetime(data, definition).should eq DateTime.parse("2012-04-18 16:37:00")
      end

      it "raises exception if datetime doesn't match the format" do
        Importu::Importer.should_receive(:clean).and_return("04-18-2012 15:22:19")
        expect { Importu::Importer.datetime(data, definition) }.to raise_error(ArgumentError)
      end

      it "raises an exception if the datetime is invalid" do
        Importu::Importer.should_receive(:clean).and_return("04/32/2012 00:00:00")
        expect { Importu::Importer.datetime(data, definition) }.to raise_error(ArgumentError)
      end
    end
  end

  describe ":field_value converter" do
    context "when a converter is not specified" do
      it "returns the clean field value" do
        Importu::Importer.should_receive(:clean).and_return(:anything)
        Importu::Importer.field_value(data, definition).should eq :anything
      end
    end

    context "when a converter is specified" do
      let(:definition) { { :label => "Mxr", :converter => Importu::Importer.converters[:integer] } }
      let(:data) { { "Mxr" => " 499  " } }

      it "calls the specified converter to get value" do
        Importu::Importer.field_value(data, definition).should eq 499
      end

      it "raises an exception if converter raises an exception" do
        expect { Importu::Importer.field_value({ "Mxr" => "9d6" }, definition) }.to raise_error(Importu::FieldParseError)
      end
    end
  end

end
