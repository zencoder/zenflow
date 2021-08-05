require 'spec_helper'

describe Zenflow::Feature do
  subject { Zenflow::Feature.new }

  it { expect(subject.flow).to eq("feature") }
  it { expect(subject.branch(:source)).to eq("master") }
  it { expect(subject.branch(:deploy)).to eq("qa") }
end
