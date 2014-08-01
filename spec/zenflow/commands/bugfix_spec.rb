require 'spec_helper'

describe Zenflow::Bugfix do

  subject { Zenflow::Bugfix.new }

  it { expect(subject.flow).to eq("bugfix") }
  it { expect(subject.branch(:source)).to eq("master") }
  it { expect(subject.branch(:deploy)).to eq("qa") }

end
