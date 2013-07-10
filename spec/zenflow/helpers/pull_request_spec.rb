require 'spec_helper'

describe Zenflow::PullRequest do
  before(:all){
    Zenflow::GithubRequest.base_uri 'https://api.github.com/repos/zencoder/zenflow-example'
  }

  describe '.list', vcr: { cassette_name: "pull request list" } do
    let(:pull_requests){Zenflow::PullRequest.list}
    it{expect(pull_requests).to be_a_kind_of(Array)}
    it{expect(pull_requests.first).to be_a_kind_of(Zenflow::PullRequest)}
  end

  describe '.find', vcr: { cassette_name: "pull request find" } do
    let(:pull_request){Zenflow::PullRequest.find(1)}
    it{expect(pull_request).to be_a_kind_of(Zenflow::PullRequest)}
  end

  describe '.find_by_ref' do
    before(:each){Zenflow.should_receive(:Log).with(Regexp.new('Looking up'))}

    context 'existing ref', vcr: { cassette_name: "pull request by ref" } do
      let(:pull_request){Zenflow::PullRequest.find_by_ref('feature/example')}
      it{expect(pull_request).to be_a_kind_of(Zenflow::PullRequest)}
    end

    context 'non-existant ref', vcr: { cassette_name: "pull request for non-existent ref" } do
      let(:pull_request){Zenflow::PullRequest.find_by_ref('feature/foo')}
      it{expect(pull_request).to be_nil}
    end
  end

  describe '.find_by_ref!' do
    before(:each){Zenflow.should_receive(:Log).with(Regexp.new('Looking up'))}

    context 'existing ref', vcr: { cassette_name: "pull request by ref" } do
      let(:pull_request){Zenflow::PullRequest.find_by_ref!('feature/example')}
      it{expect(pull_request).to be_a_kind_of(Zenflow::PullRequest)}
    end

    context 'non-existent ref', vcr: { cassette_name: "pull request for non-existent ref" } do
      let(:ref){'feature/foo'}

      it 'logs the failure' do
        Zenflow.should_receive(:Log).with(Regexp.new(ref), color: :red)
        expect{Zenflow::PullRequest.find_by_ref!(ref)}.to raise_error(SystemExit)
      end
    end
  end

  describe '.exist?' do
    before(:each){Zenflow.should_receive(:Log).with(Regexp.new('Looking up'))}

    context 'a valid pull', vcr: { cassette_name: "existing pull request" } do
      it{expect(Zenflow::PullRequest.exist?('feature/example')).to be_true}
    end

    context 'an invalid pull', vcr: { cassette_name: "unexisting pull request" } do
      it{expect(Zenflow::PullRequest.exist?('feature/foo')).to be_false}
    end
  end

  describe '.create', vcr: { cassette_name: "create pull request" } do
    let(:request_options) do
      {
        base: 'master',
        head: 'feature/new-branch',
        title: 'Feaure: new-branch',
        body: 'making a new pull request'
      }
    end
    it{ expect(Zenflow::PullRequest.create(request_options)).to(
      be_a_kind_of(Zenflow::PullRequest)
    ) }
  end

  describe '#valid?' do
    context 'good request', vcr: { cassette_name: "create pull request" } do
      let(:request){Zenflow::PullRequest.create({})}
      it{expect(request.valid?).to be_true}
    end

    context 'bad request', vcr: { cassette_name: "create bad pull request" } do
      let(:request_options) do
        {
          base: 'master',
          head: 'feature/phoney',
          title: 'this feature does not exist',
          body: 'gonna fail'
        }
      end
      let(:request){Zenflow::PullRequest.create()}
      it{expect(request.valid?).to be_false}
    end
  end

  describe '#[]' do
    context 'good request', vcr: { cassette_name: "create pull request" } do
      let(:request){Zenflow::PullRequest.create({})}
      it{expect(request["comments"]).to_not be_nil}
      it{expect(request["fdsfa"]).to be_nil}
    end
  end

end
