require 'rails_helper'

describe '#message' do
  let(:input) {
    SlackRTMInput.new({
      'channel' => 'channel',
      'text' => 'text',
      'user' => 'user',
    })
  }
  let(:output) { SlackRTMOutput.new }
  subject { BukukariSlackBot.message(input, output) }

  it '' do
    expect(subject.text).to eq ''
  end

  it '' do
    input.text = 'こんにちは'
    expect(subject.text).to eq ('こんにちは <@user> さん')
  end

end
