require 'rspec'

describe 'SampleTest' do
  before do
    # Do nothing
  end

  after do
    # Do nothing
  end

  context 'when condition' do
    it 'succeeds' do
      expect(0).to eq(0)
    end
  end
end