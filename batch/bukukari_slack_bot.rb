require 'http'
require 'json'
require 'eventmachine'
require 'faye/websocket'

class BukukariSlackBot

  def self.run
    EM.run { SlackRTMSocket.new(method(:message)) }
  end

  def self.message(input, output)
    p [:message, input]
    output.channel = input.channel
    if input.text == 'こんにちは'
      output.send_flag = true
      output.text = "こんにちは <@#{input.user}> さん"
    end
    output
  end

end

class SlackRTMInput
  attr_accessor :channel, :text, :user

  def initialize(data)
    @channel = data['channel']
    @text = data['text']
    @user = data['user']
  end
end

class SlackRTMOutput
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

class SlackRTMSocket
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
      slack_rtm_output = callback.call(SlackRTMInput.new(data), SlackRTMOutput.new)
      ws.send(slack_rtm_output.send_data) if slack_rtm_output.send?
    end
  end

  def close
    ws.on :close do
      p [:close, event.code]
      ws = nil
      EM.stop
    end
  end
end
