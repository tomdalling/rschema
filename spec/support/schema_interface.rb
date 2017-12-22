ARBITRARY_PROBLEMATIC_VALUES = [
  nil,
  -1, 0, 1, 2**128,
  -1.1, 0.0, 1.1, Float::MIN, Float::MAX, Float::NAN, Float::INFINITY,
  '', 'a', 'a'*1000,
  [], [1], [1]*1000,
  {}, {a: 1}, {a: 1, b: 2},
  Object.new, BasicObject.new,
  Kernel, Module, Class,
]

RSpec.shared_examples 'a schema' do
  it 'responds to #call' do
    expect(subject).to respond_to(:call)
    expect(subject.method(:call).arity).to eq(2)
  end

  it 'responds to #with_wrapped_subschemas' do
    expect(subject).to respond_to(:with_wrapped_subschemas)
    expect(subject.method(:with_wrapped_subschemas).arity).to eq(1)
  end

  it 'handles any value without raising an exception' do
    ARBITRARY_PROBLEMATIC_VALUES.each do |value|
      expect { subject.call(value, RSchema::Options.default) }.not_to raise_error
    end
  end
end
