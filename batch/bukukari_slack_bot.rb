require 'http'
require 'json'
require 'eventmachine'
require 'faye/websocket'

class BukukariSlackBot

  def self.run
    EM.run { SlackRtmSocket.new(method(:message)) }
  end

  def self.message(input, output)
    output.channel = input.channel
    return output if input.no_text?
    return output if input.invalid_mention?
    return output if input.no_option?
    return create(input, output) if input.create_action?
  end

  def self.create(input, output)
    Book.create(isbn: input.option)
    output.send_flag = true
    output.text = "<@#{input.user}> 登録しました"
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
