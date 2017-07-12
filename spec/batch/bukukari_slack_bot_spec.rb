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

  it 'has Book Model' do
    expect(Book.count).to eq 0
  end

  it 'create book when say "@bot create isbn"' do
    input.text = '@bot create 1234567890123'
    subject
    expect(Book.count).to eq 1
  end

  it 'create book when say "@bot create isbn"' do
    input.text = '@bot create 1234567890123'
    subject
    expect(Book.where(isbn: '1234567890123').count).to eq 1
  end

  it 'not create book when say "@bot hoge isbn"' do
    input.text = '@bot hoge 1234567890123'
    subject
    expect(Book.count).to eq 0
  end

  it 'not create book when say "@bot fuga isbn"' do
    input.text = '@bot fuga 1234567890123'
    subject
    expect(Book.count).to eq 0
  end

end
