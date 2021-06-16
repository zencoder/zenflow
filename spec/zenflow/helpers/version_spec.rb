require 'spec_helper'

describe Zenflow::Version do
  describe '.[]' do
    context 'with a hash' do
      subject{Zenflow::Version[1,0,7]}
      it_should_behave_like "a version", [1,0,7,nil]
    end

    context 'with a string' do
      subject{Zenflow::Version["#{Dir.pwd}/spec/fixtures/VERSION.yml"]}
      it_should_behave_like "a version", [1,0,0,nil]
    end
  end

  describe '.current' do
    before(:each) do
      allow(YAML).to receive(:load_file).and_return(
        {'major' => 1, 'minor' => 2, 'patch' => 4, 'pre' => nil}
      )
    end
    subject{Zenflow::Version.current}
    it_should_behave_like "a version", [1,2,4,nil]
  end

  describe '.update' do

  end

  describe '.bump' do
    before(:each) do
      allow(Zenflow::Version).to receive(:current).and_return(Zenflow::Version[1,2,4])
    end

    context 'patch' do
      subject{Zenflow::Version.current.bump(:patch)}
      it_should_behave_like "a version", [1,2,5,nil]
    end

    context 'minor' do
      subject{Zenflow::Version.current.bump(:minor)}
      it_should_behave_like "a version", [1,3,0,nil]
    end

    context 'major' do
      subject{Zenflow::Version.current.bump(:major)}
      it_should_behave_like "a version", [2,0,0,nil]
    end

    context 'invalid level' do
      it{expect{Zenflow::Version.current.bump(:foo)}.to(
        raise_error("Invalid version part")
      )}
    end
  end

  describe '#major' do
    it{expect(Zenflow::Version[1,2,4].major).to eq(1)}
  end

  describe '#minor' do
    it{expect(Zenflow::Version[1,2,4].minor).to eq(2)}
  end

  describe '#patch' do
    it{expect(Zenflow::Version[1,2,4].patch).to eq(4)}
  end

  describe '#pre' do
    it{expect(Zenflow::Version[1,2,4,'rc2'].pre).to eq('rc2')}
  end

  describe '#to_hash' do
    it{expect(Zenflow::Version[1,2,4].to_hash).to eq(
      {
        'major' => 1,
        'minor' => 2,
        'patch' => 4,
        'pre' => nil
      }
    )}
  end

  describe '#to_a' do
    it{expect(Zenflow::Version[1,2,4,'rc2'].to_a).to eq([1,2,4,'rc2'])}
  end

  describe '#to_s' do
    it{expect(Zenflow::Version[1,2,4,'rc2'].to_s).to eq('1.2.4.rc2')}
  end

  describe '#save' do
    let(:path){"#{Dir.pwd}/spec/fixtures/temp_version.yml"}
    let(:version){Zenflow::Version[1,2,5]}
    let(:file){double('file')}

    before(:each){ Zenflow::Version[1,3,4].save(path) }
    after(:each){ File.delete(path) }

    it{expect(YAML.load_file(path)).to(
      eq(
        {
          'major' => 1,
          'minor' => 3,
          'patch' => 4,
          'pre' => nil
        }
      )
    )}
  end
end
