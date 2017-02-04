require 'spec_helper'

describe TimingAttack::TestCase do
  let(:klass) { TimingAttack::TestCase }
  let(:input_param) { "dogs are cool + 1" }
  let(:test_case) do
    klass.new(
      input: input_param,
      options: {
        url: "http:/localhost:3000/",
        params: {
          login: "INPUT",
          "INPUT" => "value"
        }
      }
    )
  end
  it "should properly set params" do
    expect(test_case.send(:params)).to eq(
      login: input_param,
      input_param => "value"
    )
  end
end
