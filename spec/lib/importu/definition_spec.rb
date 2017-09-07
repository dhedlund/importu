require "spec_helper"

require "importu/definition"

RSpec.describe Importu::Definition do
  subject(:definition) { Class.new(ancestor) }
  let(:ancestor) { Class.new { extend Importu::Definition } }

  describe "#allow_actions" do
    it "updates the :allowed_actions config" do
      expect { definition.allow_actions(:create, :update) }
        .to change { definition.config[:allowed_actions] }
        .to([:create, :update])
    end

    it "inherits config from ancestor" do
      ancestor.allow_actions(:update)
      expect(definition.config[:allowed_actions]).to eq [:update]
    end

    it "does not affect ancestor config" do
      ancestor.allow_actions(:update)
      expect { definition.allow_actions(:create, :update) }
        .to_not change { ancestor.config }
    end
  end

  describe "#config" do
    it "returns a config hash of the definition" do
      expect(definition.config).to include(:converters, :fields)
    end

    it "[:allowed_actions] defaults to only allow :create" do
      expect(definition.config[:allowed_actions]).to eq [:create]
    end

    it "[:backend][:finder_fields] defaults to searching by :id" do
      expect(definition.config[:backend][:finder_fields]).to eq [[:id]]
    end
  end

  describe "#convert_to" do
    let!(:converter) do
      definition.converter :foo do |name,**options|
        "foo(#{name}, {#{options.map {|k,v| "#{k}:#{v}"}.join(",")}})"
      end
    end

    it "returns a converter stub representing the converter" do
      stub = definition.convert_to(:foo)
      expect(stub.type).to eq :foo
    end

    it "saves converter options from definition" do
      expect(definition.convert_to(:foo, a: 7).options).to eq({a: 7})
      expect(definition.convert_to(:foo).options).to eq({})
    end

    it "raises an exception if converter cannot be found" do
      expect { definition.convert_to(:bar) }.to raise_error(KeyError)
    end
  end

  describe "#converter" do
    let(:foo_block) { Proc.new {} }

    it "updates the :converters config" do
      expect { definition.converter(:foo, &foo_block) }
        .to change { definition.config[:converters][:foo] }
        .to(foo_block)
    end

    it "inherits config from ancestor" do
      ancestor.converter(:foo, &foo_block)
      expect(definition.config[:converters][:foo]).to eq foo_block
    end

    it "does not affect ancestor config" do
      ancestor.converter(:foo, &foo_block)
      expect { definition.converter(:foo) {} }
        .to_not change { ancestor.config }
    end
  end

  describe "#field" do
    let(:converter) { Proc.new {} }

    it "updates the :fields config and presets defaults" do
      definition.field(:foo, required: false)
      expect(definition.config[:fields][:foo])
        .to eq definition.field_defaults(:foo).merge(required: false)
    end

    it "inherits config from ancestors" do
      ancestor.field(:foo, required: false, &converter)
      expect(definition.config[:fields][:foo]).to include(
        required: false,
        converter: converter,
      )
    end

    it "does not affect ancestor config" do
      ancestor.field(:foo, required: false, &converter)
      expect { definition.field(:foo, abstract: true, label: "baaa") }
        .to_not change { ancestor.config }
      expect(definition.config[:fields][:foo]).to include(
        required: false,
        abstract: true,
        label: "baaa"
      )
    end

    it "allows partially updating the field config" do
      ancestor.field(:foo, required: false, &converter)
      definition.field(:foo, abstract: true, label: "baaa")
      definition.field(:foo, create: false)
      expect(definition.config[:fields][:foo]).to include(
        required: false,
        abstract: true,
        create: false,
        label: "baaa",
        converter: converter,
      )
    end

    it "defaults to using the :default converter" do
      definition.field(:foo)
      field_definition = definition.config[:fields][:foo]
      expect(field_definition[:converter].type).to eq :default
    end
  end

  describe "#fields" do
    it "configures each field with the same properties" do
      converter = Proc.new {}
      expect(definition).to receive(:field).with(:foo, required: false, &converter)
      expect(definition).to receive(:field).with(:bar, required: false, &converter)
      expect(definition).to receive(:field).with(:baz, required: false, &converter)
      definition.fields(:foo, :bar, :baz, required: false, &converter)
    end
  end

  describe "#find_by" do
    it "updates the [:backend][:finder_fields] config" do
      expect { definition.find_by(:foo, [:bar, :baz]) }
        .to change { definition.config[:backend][:finder_fields] }
        .to([:foo, [:bar, :baz]])
    end

    it "inherits config from ancestor" do
      ancestor.find_by(:foo, [:bar, :baz])
      expect(definition.config[:backend][:finder_fields])
        .to eq [:foo, [:bar, :baz]]
    end

    it "does not affect ancestor config" do
      ancestor.find_by(:foo, [:bar, :baz])
      expect { definition.find_by(:bar) }
        .to_not change { ancestor.config }
    end

    it "allows setting to a block" do
      foo_block = Proc.new {}
      expect { definition.find_by(&foo_block) }
        .to change { definition.config[:backend][:finder_fields] }
        .to([foo_block])
    end

    it "allows clearing all finder fields" do
      expect { definition.find_by(nil) }
        .to change { definition.config[:backend][:finder_fields] }
        .to([])
    end
  end

  describe "#model" do
    it "updates the :backend config" do
      expect { definition.model("Foo") }
        .to change { definition.config[:backend][:model] }
        .to("Foo")
    end

    it "inherits config from ancestor" do
      ancestor.model("Foo")
      expect(definition.config[:backend][:model]).to eq "Foo"
    end

    it "does not affect ancestor config" do
      ancestor.model("Foo")
      expect { definition.model("Bar") }
        .to_not change { ancestor.config }
    end

    it "allows specifying a backend property" do
      expect { definition.model("Foo", backend: :oven) }
        .to change { definition.config[:backend][:name] }
        .to(:oven)
    end
  end

  describe "#preprocess" do
    let(:foo_block) { Proc.new {} }

    it "updates the :preprocess config" do
      expect { definition.preprocess(&foo_block) }
        .to change { definition.config[:preprocess] }
        .to(foo_block)
    end

    it "inherits config from ancestor" do
      ancestor.preprocess(&foo_block)
      expect(definition.config[:preprocess]).to eq foo_block
    end

    it "does not affect ancestor config" do
      ancestor.preprocess(&foo_block)
      expect { definition.preprocess {} }
        .to_not change { ancestor.config }
    end
  end

  describe "#postprocess" do
    let(:foo_block) { Proc.new {} }

    it "updates the :postprocess config" do
      expect { definition.postprocess(&foo_block) }
        .to change { definition.config[:postprocess] }
        .to(foo_block)
    end

    it "inherits config from ancestor" do
      ancestor.postprocess(&foo_block)
      expect(definition.config[:postprocess]).to eq foo_block
    end

    it "does not affect ancestor config" do
      ancestor.postprocess(&foo_block)
      expect { definition.postprocess {} }
        .to_not change { ancestor.config }
    end
  end

  describe "#records_xpath" do
    let(:foo_block) { Proc.new {} }

    it "updates the :records_xpath config" do
      expect { definition.records_xpath("//books") }
        .to change { definition.config[:records_xpath] }
        .to("//books")
    end

    it "inherits config from ancestor" do
      ancestor.records_xpath("//books")
      expect(definition.config[:records_xpath]).to eq "//books"
    end

    it "does not affect ancestor config" do
      ancestor.records_xpath("//books")
      expect { definition.records_xpath("//pages") }
        .to_not change { ancestor.config }
    end
  end

end
