require "spec_helper"

require "importu/converter_context"
require "importu/converters"
require "importu/definition"
require "importu/record"

RSpec.describe Importu::Record do
  subject(:record) { Importu::Record.new(data, context, definition.config) }
  let(:context) { Importu::ConverterContext.with_config(definition.config) }

  let(:definition) do
    Class.new do
      extend Importu::Definition
      include Importu::Converters
      field :pilot
      field :balloons, &convert_to(:integer)
      field :flying, &convert_to(:boolean)
    end
  end

  let(:data) { { "pilot" => "Nena",  "balloons" => "99", "flying" => "yes" } }

  it "supports hash-like accessors" do
    expect(record[:pilot]).to eq "Nena"
    expect(record.fetch(:balloons)).to eq 99
    expect { record.fetch(:color) }.to raise_error(KeyError)
    expect(record.key?(:flying)).to be true
    expect(record.key?(:color)).to be false
    expect(record.keys).to eq [:pilot, :balloons, :flying]
    expect(record.values).to eq ["Nena", 99, true]
  end

  it "supports enumerable behaviors" do
    expect(record.each.with_index.to_a) # enumerable is composable (#w_index)
      .to eq [[[:pilot, "Nena"], 0], [[:balloons, 99], 1], [[:flying, true], 2]]

    expect(record.reduce([]) {|acc,(k,_)| acc << k }).to eq record.keys
  end

  describe "#assignable_fields_for" do
    it "returns all field names by default" do
      expect(record.assignable_fields_for(:create))
        .to eq [:pilot, :balloons, :flying]
    end

    context "when a field is allowed for create but not update" do
      let(:definition) do
        Class.new(super()) { field :pilot, create: true, update: false }
      end

      it "includes field for :create action but not :update action" do
        expect(record.assignable_fields_for(:create)).to include(:pilot)
        expect(record.assignable_fields_for(:update)).to_not include(:pilot)
      end
    end

    context "when a field is marked as abstract" do
      let(:definition) do
        Class.new(super()) { field :balloons, abstract: true }
      end

      it "excludes the abstract field from list" do
        expect(record.assignable_fields_for(:create)).to eq [:pilot, :flying]
        expect(record.assignable_fields_for(:update)).to eq [:pilot, :flying]
      end
    end
  end

  describe "#data" do
    it "returns data supplied during initialization" do
      expect(record.data).to eq data
    end
  end

  describe "#errors" do
    it "returns []" do
      expect(record.errors).to eq []
    end

    context "when one or more values could not be converted" do
      let(:data) { super().merge!("balloons" => "many", "flying" => "maybe") }

      it "returns list of field parse errors for failed conversions" do
        expect(record.errors.map(&:field_name))
          .to match_array([:balloons, :flying])
      end
    end
  end

  describe "#to_hash" do
    it "returns data with field converters applied" do
      expect(record.to_hash).to eq(pilot: "Nena", balloons: 99, flying: true)
    end

    it "does not try to recovert the data each time (returns same has)" do
      expect(record.to_hash.object_id).to eq record.to_hash.object_id
    end

    context "when one or more values could not be converted" do
      let(:data) { super().merge!("flying" => "maybe") }

      it "raises an InvalidRecord error with errors from field conversion" do
        expect { record.to_hash }.to raise_error(Importu::InvalidRecord)

        begin
          record.to_hash
        rescue Importu::InvalidRecord => e
          expect(e.validation_errors.count).to eq 1
          expect(e.validation_errors.first.field_name).to eq :flying
        end
      end
    end
  end

  describe "#valid?" do
    context "when all values can be converted successfully" do
      it "returns true" do
        expect(record).to be_valid
      end
    end

    context "when one or more values could not be converted" do
      let(:data) { super().merge!("flying" => "maybe") }

      it "returns false" do
        expect(record).to_not be_valid
      end
    end
  end

end
