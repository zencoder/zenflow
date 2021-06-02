require 'spec_helper'

describe Zenflow::Hotfix do

  subject { Zenflow::Hotfix.new }

  it { expect(subject.flow).to eq("hotfix") }
  it { expect(subject.branch(:source)).to be false }
  it { expect(subject.branch(:deploy)).to match_array(["staging", "qa"]) }
  it { expect(subject.branch(:secondary_destination)).to eq("master") }
  it { expect(subject.changelog).to eq(:rotate) }
  it { expect(subject.version).to eq(:patch) }
  it { expect(subject.tag).to be_truthy }

end
