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

  describe "#data" do
    it "returns data supplied during initialization" do
      expect(record.data).to eq data
    end
  end

  describe "#to_hash" do
    it "returns data with field converters applied" do
      expect(record.to_hash).to eq(pilot: "Nena", balloons: 99, flying: true)
    end

    it "does not try to recovert the data each time (returns same has)" do
      expect(record.to_hash.object_id).to eq record.to_hash.object_id
    end
  end

end
