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

RSpec.describe Importu::DuplicateManager::BackendProxy do
  subject(:proxy) { described_class.new(dummy_backend, backend_config) }

  let(:dummy_backend) { DummyBackend.new(backend_config) }
  let(:backend_config) { definition.config[:backend] }

  let(:definition) do
    Class.new do
      extend Importu::Definition
      fields :foo, :bar, :baz
      find_by :foo, :bar
    end
  end

  describe "#create" do
    it "returns the status and object from the backend" do
      status, object = proxy.create(foo: 1, bar: 1, baz: 1)
      expect(status).to eq :created
      expect(object).to include(foo: 1, bar: 1, baz: 1)
    end

    it "perform duplicate detection on the record" do
      proxy.create(foo: 1, bar: 1, baz: 1)
      expect { proxy.create(foo: 2, bar: 1, baz: 2) } # :baz is a dupe find_by
        .to raise_error(Importu::DuplicateRecord)
    end

    it "records created object for subsequent dupe detection" do
      proxy.create(foo: 1, bar: 1, baz: 1)
      expect { proxy.create(foo: 2, bar: 1, baz: 2) }
        .to raise_error(Importu::DuplicateRecord)
    end
  end

  describe "#update" do
    it "returns the status and object from the backend" do
      _, object = dummy_backend.create(foo: 1, bar: 1, baz: 1)
      status, new_object = proxy.update({foo: 2, bar: 2, baz: 2}, object)

      expect(status).to eq :updated
      expect(new_object).to include(foo: 2, bar: 2, baz: 2)
    end

    it "perform duplicate detection on the record" do
      _status, object = proxy.create(foo: 1, bar: 1, baz: 1)

      expect(dummy_backend).to_not receive(:update)
      expect { proxy.update({foo: 1, bar: 2, baz: 2}, object) } # :foo is a dupe
        .to raise_error(Importu::DuplicateRecord)
    end

    it "performs duplicate detection on object" do
      # Existing db record, never accessed through dupe detector
      _status, object = dummy_backend.create(foo: 1, bar: 1, baz: 1)

      # Update via :foo, first encounter of k/v and first encounter of object
      expect { proxy.update({foo: 1, bar: 2, baz: 3}, object) }.to_not raise_error

      # Update via :bar, first encounter of k/v, but second encounter of object
      expect { proxy.update({foo: 2, bar: 1, baz: 3}, object) }
        .to raise_error(Importu::DuplicateRecord)
    end
  end

end
