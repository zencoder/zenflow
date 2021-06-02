require 'spec_helper'

describe Zenflow::Release do

  subject { Zenflow::Release.new }

  it { expect(subject.flow).to eq("release") }
  it { expect(subject.branch(:source)).to eq("master") }
  it { expect(subject.branch(:destination)).to be false }
  it { expect(subject.branch(:deploy)).to match_array(["staging", "qa"]) }
  it { expect(subject.changelog).to eq(:rotate) }
  it { expect(subject.version).to eq(:minor) }
  it { expect(subject.tag).to be_truthy }

end
