# frozen_string_literal: true

require "spec_helper"

require "importu/sources/ruby"
require "importu/summary"

RSpec.describe Importu::Sources::Ruby do
  subject(:source) { described_class.new(data) }

  describe "#initialize" do
    let(:data) { [] }

    it "accepts an array" do
      expect { source }.not_to raise_error
    end

    it "accepts any enumerable" do
      source = described_class.new([1, 2, 3].each)
      expect(source).to be_a(described_class)
    end
  end

  describe "#rows" do
    context "with an array of hashes" do
      let(:data) { [{ "name" => "Alice" }, { "name" => "Bob" }] }

      it "returns an enumerator" do
        expect(source.rows).to be_a(Enumerator)
      end

      it "yields each hash" do
        expect(source.rows.to_a).to eq data
      end

      it "can be iterated multiple times" do
        first_pass = source.rows.to_a
        second_pass = source.rows.to_a
        expect(second_pass).to eq first_pass
      end
    end

    context "with objects responding to to_hash" do
      let(:hashable_object) do
        Class.new do
          def initialize(name)
            @name = name
          end

          def to_hash
            { "name" => @name }
          end
        end
      end

      let(:data) { [hashable_object.new("Alice"), hashable_object.new("Bob")] }

      it "converts each object via to_hash" do
        expect(source.rows.to_a).to eq [{ "name" => "Alice" }, { "name" => "Bob" }]
      end
    end

    context "with empty array" do
      let(:data) { [] }

      it "returns 0 rows" do
        expect(source.rows.count).to eq 0
      end
    end

    context "with symbol keys in hashes" do
      let(:data) { [{ name: "Alice" }] }

      # NOTE: The Ruby source calls to_hash which preserves symbol keys.
      # However, importu field definitions use string keys by default.
      # Users should ensure their hash keys match what fields expect.
      it "preserves symbol keys (caller must ensure key type matches)" do
        expect(source.rows.first.keys).to eq [:name]
      end
    end
  end

  describe "#write_errors" do
    let(:data) { [{ "name" => "Alice" }] }

    let(:summary) do
      Importu::Summary.new.tap do |s|
        s.record(:invalid, index: 0, errors: ["name was invalid"])
      end
    end

    # The Ruby source has a stub implementation that does nothing.
    # This is intentional - there's no sensible file output for in-memory data.
    it "returns nil (stub implementation)" do
      expect(source.write_errors(summary)).to be_nil
    end

    it "accepts only_errors option without error" do
      expect { source.write_errors(summary, only_errors: true) }.not_to raise_error
    end
  end
end
