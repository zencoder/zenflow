require 'spec_helper'

describe Zenflow::Chore do

  subject { Zenflow::Chore.new }

  it { expect(subject.flow).to eq("chore") }
  it { expect(subject.branch(:source)).to eq("master") }
  it { expect(subject.branch(:deploy)).to eq("qa") }

end
