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

  it 'get msg when say @bot search {isbn}' do
    Book.create!(isbn: '11111')
    Book.create!(isbn: '11111')
    input.user = 'user'
    input.text = '<@U5XABMCFP> search 11111'
    expect(subject.text).to include '<@user>¥ 2件ヒットしました'
  end

  it 'get msg when say @bot search {isbn}' do
    Book.create!(isbn: '11111')
    input.user = 'user'
    input.text = '<@U5XABMCFP> search 11111'
    expect(subject.text).to include '<@user> 1件ヒットしました'
  end

  it 'get msg when say @bot search {isbn}' do
    input.user = 'user'
    input.text = '<@U5XABMCFP> search 222222'
    expect(subject.text).to include '<@user> 0件ヒットしました'
  end

  it 'get msg when say @bot search {isbn}' do
    Book.create!(isbn: '11111')
    input.user = 'user'
    input.text = '<@U5XABMCFP> search 111'
    expect(subject.text).to include '<@user> 1件ヒットしました'
  end

  it '' do
    Book.create!(isbn: 'hoge111')
    input.user = 'user'
    input.text = '<@U5XABMCFP> search e'
    expect(subject.text).to include '<@user> 1件ヒットしました'
  end

  it 'show the search detail when you say "@bot search {isbn}" ' do
    Book.create!(isbn: 'hoge111')
    input.user = 'user'
    input.text = '<@U5XABMCFP> search hoge111'
    expect(subject.text).to eq "<@user> 1件ヒットしました\n 1.ISBN: hoge111"
  end

  it 'show the search detail when you say "@bot search {isbn}" ' do
    Book.create!(isbn: 'hoge111')
    Book.create!(isbn: 'huga111')
    input.user = 'user'
    input.text = '<@U5XABMCFP> search 111'
    expect(subject.text).to eq "<@user> 2件ヒットしました\n 1.ISBN: hoge111\n 2.ISBN: huga111"
  end

  it 'show the search detail when you say "@bot search {isbn}" ' do
    Book.create!(isbn: 'hoge111')
    Book.create!(isbn: 'huga111')
    input.user = 'user2'
    input.text = '<@U5XABMCFP> search 111'
    expect(subject.text).to eq "<@user2> 2件ヒットしました\n 1.ISBN: hoge111\n 2.ISBN: huga111"
  end
end
