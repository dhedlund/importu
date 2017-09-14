require "spec_helper"

require "importu/exceptions"

RSpec.describe Importu::DuplicateManager do
  subject(:duplicates) { described_class.new(finder_fields: finder_fields) }

  let(:finder_fields) { [] }

  describe "#check_object!" do
    it "allows different unique ids to be set without any errors" do
      duplicates.check_object!(9164)
      expect { duplicates.check_object!(9165) }.to_not raise_error
    end

    it "raises a DuplicateRecord when unique on subsequent encounters" do
      duplicates.check_object!(9164)
      expect { duplicates.check_object!(9164) }
        .to raise_error(Importu::DuplicateRecord)
    end
  end

  describe "#check_record!" do
    context "when no finder fields are defined" do
      let(:finder_fields) { [] }

      it "never considers records to be duplicates" do
        duplicates.check_record!(foo: 3, bar: 4)
        expect { duplicates.check_record!(foo: 3, bar: 4) }.to_not raise_error
      end
    end

    context "when a finder field is defined" do
      let(:finder_fields) { [[:foo]] }

      it "allows different values to be set without any errors" do
        duplicates.check_record!(foo: 3, bar: 4)
        expect { duplicates.check_record!(foo: 4, bar: 4) }.to_not raise_error
      end
    end

    context "when multiple finder field groups are defined" do
      let(:finder_fields) { [[:foo, :bar], [:bar, :baz], [:qux]] }

      it "records and matches against all field groups" do
        duplicates.check_record!(foo: 1, bar: 1, baz: 1, qux: 1)

        # Each field group has a unique set of values from previous check
        duplicates.check_record!(foo: 1, bar: 2, baz: 1, qux: 2)

        # The second field group conflicts with values from previous check
        expect { duplicates.check_record!(foo: 2, bar: 2, baz: 1, qux: 3) }
          .to raise_error(Importu::DuplicateRecord)
      end

      it "adds all non-duplicate field groups, even if exception is raised" do
        duplicates.check_record!(foo: 1, bar: 1, baz: 1, qux: 1)

        # Only first field group is duplicate, but others should still get added
        expect { duplicates.check_record!(foo: 1, bar: 1, baz: 2, qux: 2) }
          .to raise_error(Importu::DuplicateRecord)

        expect { duplicates.check_record!(bar: 1, baz: 2) }
          .to raise_error(Importu::DuplicateRecord)
        expect { duplicates.check_record!(qux: 2) }
          .to raise_error(Importu::DuplicateRecord)
      end
    end

    context "when a proc-based finder field is defined" do
      let(:finder_fields) { [Proc.new { raise :bleep }, [:foo]] }

      it "ignores proc-based field groups" do
        duplicates.check_record!(foo: 3, bar: 4)
        duplicates.check_record!(foo: 4, bar: 4)
        expect { duplicates.check_record!(foo: 3, bar: 5) }
          .to raise_error(Importu::DuplicateRecord)
      end
    end

    context "when a field in a finder field group is does not exist on the record" do
      let(:finder_fields) { [[:foo, :baz]] }

      it "ignores the field group when doing duplicate checking" do
        duplicates.check_record!(foo: 3, bar: 4)
        expect { duplicates.check_record!(foo: 3, bar: 4) }.to_not raise_error
      end
    end
  end

end
