require 'rails_helper'
require Rails.root.join('batch/bukukari_slack_bot.rb')

describe '#message' do
  let(:input) {
    SlackRtmInput.new({
      'channel' => 'channel',
      'text' => 'text',
      'user' => 'user',
    })
  }
  let(:output) { SlackRtmOutput.new }
  subject { BukukariSlackBot.message(input, output) }

  it 'say こんにちは when input こんにちは' do
    input.text = 'こんにちは'
    expect(subject.text).to eq ('こんにちは <@user> さん')
  end

  it 'say create when input create' do
    input.text = 'create'
    expect(subject.text).to eq ('created by <@user>')
  end

end
