require 'spec_helper'

describe Importu::Record do
  subject(:record) { build(:importer_record) }

  it "includes Enumerable" do
    record.should be_a_kind_of(Enumerable)
  end

  describe "#importer" do
    it "returns the importer used during construction" do
      importer = build(:importer)
      record = build(:importer_record, :importer => importer)
      record.importer.should be importer
    end

    it "is delegated from #preprocessor" do
      record.should delegate(:preprocessor).to(:importer)
    end

    it "is delegated from #postprocessor" do
      record.should delegate(:postprocessor).to(:importer)
    end

    it "is delegated from #definitions" do
      record.should delegate(:definitions).to(:importer)
    end

    it "is delegated from #converters" do
      record.should delegate(:converters).to(:importer)
    end
  end

  describe "#data" do
    it "returns the data used during construction" do
      data = { "foo" => "bar" }
      record = build(:importer_record, :data => data)
      record.data.should == data
    end
  end

  describe "#raw_data" do
    it "returns the raw_data used during construction" do
      raw_data = "this,is\tsome_raw_data\n"
      record = build(:importer_record, :raw_data => raw_data)
      record.raw_data.should == raw_data
    end
  end

  describe "#definitions" do
    it "returns the definitions defined in importer on construction" do
      importer = build(:importer)
      importer.stub(:definitions => { :foo => :bar })
      record = build(:importer_record, :importer => importer)
      record.definitions.should be importer.definitions
    end
  end

  describe "#record_hash" do
    it "tries to generate a record hash on first access" do
      expected = { :foo => 1, :bar => 2 }
      record.should_receive(:generate_record_hash).and_return(expected)
      record.record_hash.should eq expected
    end

    it "should not try to regenerate record hash no subsequent access" do
      expected = { :foo => 1, :bar => 2 }
      record.should_receive(:generate_record_hash).once.and_return(expected)
      record.record_hash
      record.record_hash.should eq expected
    end

    it "is aliased from #to_hash" do
      record.should_receive(:record_hash).and_return(:called)
      record.to_hash.should == :called
    end

    it "is delegated from #keys" do
      record.should delegate(:keys).to(:record_hash)
    end

    it "is delegated from #values" do
      record.should delegate(:values).to(:record_hash)
    end

    it "is delegated from #each" do
      record.should delegate(:each).to(:record_hash)
    end

    it "is delegated from #[]" do
      record.should delegate(:[]).to(:record_hash)
    end

    it "is delegated from #key?" do
      record.should delegate(:key?).to(:record_hash)
    end

    describe "#convert" do
      context "with a :default option" do
        it "returns data value if data value not nil" do
          record.converters[:clean] = proc { "value1" }
          record.convert(:field1, :clean, :default => "foobar").should eq "value1"
        end

        it "returns default value if data value is nil" do
          record.converters[:clean] = proc { nil }
          record.convert(:field1, :clean, :default => "foobar").should eq "foobar"
        end

        it "returns default value if data field is missing and not required" do
          record.converters[:clean] = proc { raise Importu::MissingField, "field1" }
          record.convert(:field1, :clean, :default => "foobar").should eq "foobar"
        end

        it "raises an exception if data field is missing and is required" do
          record.converters[:clean] = proc { raise Importu::MissingField, "field1" }
          expect { record.convert(:field1, :clean, :default => "foobar", :required => true) }.to raise_error(Importu::MissingField)
        end
      end
    end

  end
end
