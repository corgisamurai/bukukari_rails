require 'rails_helper'
require Rails.root.join('batch/bukukari_slack_bot.rb')

describe '#message' do
  let(:json) {
    JSON.parse('{
      "items": [
          {
              "volumeInfo": {
                  "title": "やさしいJava",
                  "imageLinks": {
                    "thumbnail": "http://books.google.com/books/content?id=7IeFDAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api"
                  }
              }
          }
      ], 
      "totalItems": "266"
  }')
  }
  let(:exist_isbn) { '9784797388268' }
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

  it 'not create book when say "@bot hoge isbn"' do
    input.text = "<@U5XABMCFP> hoge #{exist_isbn}"
    subject
    expect(Book.count).to eq 0
  end

  it 'not create book when say "@bot fuga isbn"' do
    input.text = "<@U5XABMCFP> fuga #{exist_isbn}"
    subject
    expect(Book.count).to eq 0
  end

  it 'no response when no text' do
    input.text = nil
    expect(subject.send_flag).to be_falsey
  end

  it 'get msg when say @bot search {isbn}' do
    Book.create!(isbn: '11111')
    Book.create!(isbn: '11111')
    input.user = 'user'
    input.text = '<@U5XABMCFP> search 11111'
    expect(subject.text).to include '<@user> 2件ヒットしました'
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
    expect(subject.text).to include "<@user> 1件ヒットしました\n 1.ISBN: hoge111"
  end

  it 'show the search detail when you say "@bot search {isbn}" ' do
    Book.create!(isbn: 'hoge111')
    Book.create!(isbn: 'huga111')
    input.user = 'user'
    input.text = '<@U5XABMCFP> search 111'
    expect(subject.text).to include "<@user> 2件ヒットしました"
    expect(subject.text).to include "1.ISBN: hoge111"
    expect(subject.text).to include "2.ISBN: huga111"
  end

  it 'show the search detail when you say "@bot search {isbn}" ' do
    Book.create!(isbn: 'hoge111')
    Book.create!(isbn: 'huga111')
    input.user = 'user2'
    input.text = '<@U5XABMCFP> search 111'
    expect(subject.text).to include "<@user2> 2件ヒットしました"
  end

  it 'show the search detail with title when you say "@bot search {isbn}" ' do
    Book.create!(isbn: 'hoge111', title: 'やさしいJava')
    input.user = 'user'
    input.text = '<@U5XABMCFP> search hoge111'
    expect(subject.text).to include "<@user> 1件ヒットしました\n 1.ISBN: hoge111 TITLE: やさしいJava"
  end

    it 'show the search detail with title when you say "@bot search {book title}" ' do
      Book.create!(isbn: 'hoge111', title: 'やさしいJava')
      input.user = 'user'
      input.text = '<@U5XABMCFP> search やさしいJava'
      expect(subject.text).to include "<@user> 1件ヒットしました\n 1.ISBN: hoge111 TITLE: やさしいJava"
    end

    it 'has title in Book' do
      Book.create(title: 'test')
    end

    it 'no response when not @bot mention' do
      input.text = '@user create 1234567890123'
      expect(subject.send_flag).to be_falsey
    end

    it 'no isbn' do
      input.text = '<@U5XABMCFP> create'
      expect(subject.send_flag).to be_falsey
    end


    context 'create' do
      before do
        allow_any_instance_of(GoogleBookApi).to receive(:request).and_return(json)
      end
      it 'reply to the user by bot when say "@bot create ISBN"' do
        input.text = "<@U5XABMCFP> create #{exist_isbn}"
        expect(subject.send_flag).to be_truthy
      end

      it 'reply "@user 登録しました" by bot when say "@bot create ISBN"' do
        input.text = "<@U5XABMCFP> create #{exist_isbn}"
        expect(subject.text).to include '<@user> 登録しました TITLE: やさしいJava'
      end

      it 'reply "@hogehoge 登録しました" by bot when say "@bot create ISBN"' do
        input.text = "<@U5XABMCFP> create #{exist_isbn}"
        input.user = 'hogehoge'
        expect(subject.text).to include '<@hogehoge> 登録しました'
      end

      it 'reply image url by bot when say "@bot create ISBN"' do
        input.text = "<@U5XABMCFP> create #{exist_isbn}"
        expect(subject.text).to include 'IMAGE_URL: http://books.google.com'
      end

      it 'create book with title' do
        input.text = '<@U5XABMCFP> create 9784043636037'
        subject
        expect(Book.last.title).to eq 'やさしいJava'
      end

      it 'create book when say "@bot create isbn"' do
        input.text = "<@U5XABMCFP> create #{exist_isbn}"
        subject
        expect(Book.count).to eq 1
      end

      it 'create book when say "@bot create isbn"' do
        input.text = "<@U5XABMCFP> create #{exist_isbn}"
        subject
        expect(Book.where(isbn: exist_isbn).count).to eq 1
      end

      it 'dont create book if not exist book information' do
        allow_any_instance_of(GoogleBookApi).to receive(:book).and_return(nil)
        input.text = '<@U5XABMCFP> create 3'
        subject
        expect(Book.last).to be nil 
      end

      it 'say no data if not exist isbn' do
        allow_any_instance_of(GoogleBookApi).to receive(:book).and_return(nil)
        input.text = '<@U5XABMCFP> create 3'
        expect(subject.text).to eq '指定したISBNコードは存在しません'
      end

      it 'create book when create already' do
        allow_any_instance_of(GoogleBookApi).to receive(:book).and_return(json)
        Book.create!(isbn: '9784797388268', title: 'やさしいJava')
        input.text = '<@U5XABMCFP> create 9784797388268'
        expect(subject.text).to eq 'すでに登録されています'
      end
    end

    context 'borrow' do
      let(:book){ Book.create!(isbn: '9784797388268', title: 'やさしいJava')}

      before do
        book
      end

      it 'reply "@user 貸出ししました" by bot when say "@bot borrowやさしいJava"' do
        input.text = "<@U5XABMCFP> borrow やさしいJava"
        input.user = 'hogehoge'
        expect(subject.text).to include '<@hogehoge> 貸出ししました TITLE: やさしいJava'
      end

      it 'create borrow data' do
        borrow_check 'やさしいJava'
      end

      it 'create borrow data with ISBN' do
        borrow_check '9784797388268'
      end

      def borrow_check(title)
        input.text = "<@U5XABMCFP> borrow #{title}"
        input.user = 'hogehoge'
        subject
        result = Borrow.last
        expect(result.borrower).to eq 'hogehoge'
        expect(result.book_id).to eq book.id
      end

      it 'show the message when the book has been already borrowed' do
        Borrow.create!(borrower: 'hogehoge', book_id: book.id)
        input.text = "<@U5XABMCFP> borrow 9784797388268"
        input.user = 'fugafuga'
        expect(subject.text).to include '<@fugafuga> hogehogeさんに貸出中です TITLE: やさしいJava'
      end

      it 'show the message when the book dose not exist' do
        input.text = "<@U5XABMCFP> borrow やさしいRuby "
        input.user = 'fugafuga'
        expect(subject.text).to include '<@fugafuga> そのような本はございません'
      end


    end
end
