require 'http'
require 'json'
require 'eventmachine'
require 'faye/websocket'
require 'net/http'
require 'net/https'
require 'uri'

class GoogleBookApi

  def request(isbn)
    https = Net::HTTP.new("www.googleapis.com", 443) 
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    res = https.start { |w|
      w.get("/books/v1/volumes?q=isbn:#{isbn}")
    }
    JSON.parse(res.body)
  end

  def book(isbn)
    json = request(isbn)
    if json['totalItems'] == 0
      nil
    else
      json['items'][0]
    end
  end

end

class BukukariSlackBot

  def self.run
    EM.run { SlackRtmSocket.new(method(:message)) }
  end

  def self.message(input, output)
    output.channel = input.channel

    return output if input.no_text?
    return output if input.invalid_mention?
    return output if input.no_option?
    return search(input, output) if input.search_action? 
    return create(input, output) if input.create_action?
    return output
  end

  def self.create(input, output)
    book = GoogleBookApi.new.book(input.option)
    if book.nil?
      output.send_flag = true
      output.text = '指定したISBNコードは存在しません'
      return output
    end
    book_title = book['volumeInfo']['title']
    image_url = book['volumeInfo']['imageLinks']["thumbnail"]
    Book.create(isbn: input.option, title: book_title)
    output.send_flag = true
    output.text = "<@#{input.user}> 登録しました TITLE: #{book_title} IMAGE_URL: #{image_url}"
    output
  end

  def self.search(input, output)
    output.send_flag = true
    books = Book
      .where('isbn like ?', "%#{input.option}%")
      .or(Book.where('title like ?', "%#{input.option}%"))
    output.text = "<@#{input.user}> #{books.count}件ヒットしました\n"
    output.text += books.map.with_index { |book,i| " #{i+1}.ISBN: #{book.isbn} TITLE: #{book.title}" }.join("\n")
    output
  end

end

class SlackRtmInput
  attr_accessor :channel, :text, :user

  def initialize(data)
    @channel = data['channel']
    @text = data['text']
    @user = data['user']
  end

  def no_text?
    text == nil
  end

  def no_option?
    text.split(' ').count < 3
  end

  def mention
    text.split(' ')[0]
  end

  def action
    text.split(' ')[1]
  end

  def option
    text.split(' ')[2]
  end

  def create_action?
    action == 'create'
  end
  
  def search_action?
    action == 'search'
  end

  def invalid_mention?
    mention != '<@U5XABMCFP>'
  end
end

class SlackRtmOutput
  attr_accessor :send_flag, :type, :text, :channel

  def initialize
    @send_flag = false
    @type = 'message'
    @text = ''
    @channel = ''
  end

  def send?
    send_flag
  end

  def send_data
    { type: type, text: text, channel: channel }.to_json
  end
end

class SlackRtmSocket
  attr_accessor :ws, :callback

  def initialize(callback)
    response = HTTP.post('https://slack.com/api/rtm.start', params: { token: ENV['SLACK_API_TOKEN'] })
    @ws = Faye::WebSocket::Client.new(JSON.parse(response.body)['url'])
    @callback = callback
    set_event
  end

  def set_event
    open
    message
    close
  end

  def open
    ws.on :open do
      p [:open]
    end
  end

  def message
    ws.on :message do |event|
      data = JSON.parse(event.data)
      p [:message, data]
      slack_rtm_output = callback.call(SlackRtmInput.new(data), SlackRtmOutput.new)
      ws.send(slack_rtm_output.send_data) if slack_rtm_output.send?
    end
  end

  def close
    ws.on :close do |event|
      p [:close, event.code]
      ws = nil
      EM.stop
    end
  end
end
