require "spec_helper"

require "importu/summary"

RSpec.describe Importu::Summary do
  subject(:summary) { Importu::Summary.new }

  describe "#record" do
    it "allows incrementing :created count" do
      expect { summary.record(:created) }.to change { summary.created }.by(1)
      expect { summary.record(:created) }.to change { summary.total }.by(1)
    end

    it "allows incrementing :updated count" do
      expect { summary.record(:updated) }.to change { summary.updated }.by(1)
      expect { summary.record(:updated) }.to change { summary.total }.by(1)
    end

    it "allows incrementing :unchanged count" do
      expect { summary.record(:unchanged) }.to change { summary.unchanged }.by(1)
      expect { summary.record(:unchanged) }.to change { summary.total }.by(1)
    end

    it "allows incrementing :invalid count" do
      expect { summary.record(:invalid) }.to change { summary.invalid }.by(1)
      expect { summary.record(:invalid) }.to change { summary.total }.by(1)
    end

    it "records errors associated with :invalid results" do
      summary.record(:invalid, errors: ["foo was invalid", "bar was invalid"])
      expect(summary.validation_errors.count).to eq 2
    end
  end

  describe "#result_msg" do
    it "includes a summary of recorded counts" do
      5.times { summary.record(:created) }
      4.times { summary.record(:updated) }
      3.times { summary.record(:unchanged) }
      2.times { summary.record(:invalid, errors: ["foo was invalid"]) }
      1.times { summary.record(:invalid, errors: ["bar was invalid"]) }

      expect(summary.result_msg).to match(/total:\s*15/i)
      expect(summary.result_msg).to match(/created:\s*5/i)
      expect(summary.result_msg).to match(/updated:\s*4/i)
      expect(summary.result_msg).to match(/unchanged:\s*3/i)
      expect(summary.result_msg).to match(/invalid:\s*3/i)
    end

    context "when there are no validation errors" do
      it "does not include a breakdown of errors" do
        expect(summary.result_msg).to_not match(/validation errors/i)
      end
    end

    context "when there are validation errors" do
      it "includes a breakdown of errors" do
        3.times { summary.record(:invalid, errors: ["foo was invalid"]) }
        2.times { summary.record(:invalid, errors: ["bar was invalid"]) }

        expect(summary.result_msg).to match(/validation errors/i)
        expect(summary.result_msg).to match(/foo was invalid:\s*3/i)
        expect(summary.result_msg).to match(/bar was invalid:\s*2/i)
      end
    end
  end

  describe "#to_hash" do
    it "returns summary counts as a hash" do
      5.times { summary.record(:created) }
      4.times { summary.record(:updated) }
      3.times { summary.record(:unchanged) }
      2.times { summary.record(:invalid, errors: ["foo was invalid"]) }
      1.times { summary.record(:invalid, errors: ["bar was invalid"]) }

      expect(summary.to_hash).to include({
        created: 5,
        invalid: 3,
        unchanged: 3,
        updated: 4,
        total: 15,
      })
    end

    context "when there are no validation errors" do
      it "includes an empty hash of errors" do
        expect(summary.to_hash[:validation_errors]).to eq({})
      end
    end

    context "when there are validation errors" do
      it "includes a breakdown of errors" do
        2.times { summary.record(:invalid, errors: ["foo was invalid"]) }
        1.times { summary.record(:invalid, errors: ["bar was invalid"]) }

        expect(summary.to_hash[:validation_errors]).to eq({
          "foo was invalid" => 2,
          "bar was invalid" => 1,
        })
      end
    end
  end

  describe "#to_s" do
    it "returns same summary as #result_msg" do
      expect(summary.to_s).to eq summary.result_msg
    end
  end

  describe "#validation_errors" do
    context "when no errors" do
      it "returns an empty hash" do
        expect(summary.validation_errors).to eq({})
      end
    end

    context "when multiple errors" do
      it "counts each occurrence of error message" do
      summary.record(:invalid, errors: ["foo was invalid", "bar was invalid"])
      summary.record(:invalid, errors: ["bar was invalid", "baz was invalid"])
      expect(summary.validation_errors["foo was invalid"]).to eq 1
      expect(summary.validation_errors["bar was invalid"]).to eq 2
      expect(summary.validation_errors["baz was invalid"]).to eq 1
      end
    end

    context "when errors contain data within parentheses" do
      it "strips out parenthesis and data within if at end of error" do
        summary.record(:invalid, errors: ["lost parrot (polly)"])
        summary.record(:invalid, errors: ["lost parrot (cracker)"])
        expect(summary.validation_errors["lost parrot"]).to eq 2
      end
    end
  end
end
