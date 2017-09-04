# Allows stubbing converters in a way that doesn't pollute the main
# converter registry. This is meant to be a temporary solution until
# definitions are cloned, or converter implementation changes.
#
# This mixin expects a `let(:record) { ... }` to be defined.
#
module ConverterStubbing
  def self.included(base)
    base.around(:each) do |example|
      @stubbed_converters = {}
      begin
        example.run
      ensure
        @stubbed_converters.each do |name,orig|
          record.converters[name] = orig
        end
      end
    end
  end

  def stub_converter(name, &block)
    unless @stubbed_converters.key?(name)
      @stubbed_converters[name] = record.converters[name]
    end
    record.converters[name] = block
  end

  # To test if the above code is still necessary, it should be possible
  # to replace the above `stub_converter` method with the following and
  # ensure all the tests still pass after a few iterations of the suite.
  #
  #   def stub_converter(name, &block)
  #     record.converters[name] = block
  #   end

end
