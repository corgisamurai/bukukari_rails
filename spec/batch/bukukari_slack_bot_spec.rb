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

  it 'has Book Model' do
    expect(Book.count).to eq 0
  end

  it 'create book when say "@bot create isbn"' do
    input.text = '<@U5XABMCFP> create 1234567890123'
    subject
    expect(Book.count).to eq 1
  end

  it 'create book when say "@bot create isbn"' do
    input.text = '<@U5XABMCFP> create 1234567890123'
    subject
    expect(Book.where(isbn: '1234567890123').count).to eq 1
  end

  it 'not create book when say "@bot hoge isbn"' do
    input.text = '<@U5XABMCFP> hoge 1234567890123'
    subject
    expect(Book.count).to eq 0
  end

  it 'not create book when say "@bot fuga isbn"' do
    input.text = '<@U5XABMCFP> fuga 1234567890123'
    subject
    expect(Book.count).to eq 0
  end

  it 'no response when no text' do
    input.text = nil
    expect(subject.send_flag).to be_falsey
  end

  it 'reply to the user by bot when say "@bot create ISBN"' do
    input.text = '<@U5XABMCFP> create 1234567890123'
    expect(subject.send_flag).to be_truthy
  end

  it 'reply "@user 登録しました" by bot when say "@bot create ISBN"' do
    input.text = '<@U5XABMCFP> create 1234567890123'
    expect(subject.text).to eq '<@user> 登録しました'
  end

  it 'reply "@hogehoge 登録しました" by bot when say "@bot create ISBN"' do
    input.text = '<@U5XABMCFP> create 1234567890123'
    input.user = 'hogehoge'
    expect(subject.text).to eq '<@hogehoge> 登録しました'
  end

  it 'no response when not @bot mention' do
    input.text = '@user create 1234567890123'
    expect(subject.send_flag).to be_falsey
  end

  it 'no isbn' do
    input.text = '<@U5XABMCFP> create'
    expect(subject.send_flag).to be_falsey
  end
end
