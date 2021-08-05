require 'spec_helper'

describe Zenflow::Bug do
  subject { Zenflow::Bug.new }

  it { expect(subject.flow).to eq("bug") }
  it { expect(subject.branch(:source)).to eq("master") }
  it { expect(subject.branch(:deploy)).to eq("qa") }
end
