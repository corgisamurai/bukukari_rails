require 'http'
require 'json'
require 'eventmachine'
require 'faye/websocket'

class Bot

  @@slack_rtm_url = 'https://slack.com/api/rtm.start'
  @@slack_token = ENV['SLACK_API_TOKEN']

  def self.run
    response = HTTP.post(@@slack_rtm_url, params: { token: @@slack_token })
    rtm_url = JSON.parse(response.body)['url']
    EM.run { Socket.new(rtm_url).set_event }
  end

  def self.sample
    'works'
  end

end

class Socket

  attr_accessor :ws

  def initialize(rtm_url)
    @ws = Faye::WebSocket::Client.new(rtm_url)
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
      result = func(data)
      ws.send(result[:send_data].to_json) if result[:send_flag]
    end
  end

  def func(data)
    p [:message, data]
    result = {
      send_flag: false,
      send_data: { type: 'message', text: "", channel: data['channel'] }
    }
    if data['text'] == 'こんにちは'
      result[:send_flag] = true
      result[:send_data][:text] = "こんにちは <@#{data['user']}> さん"
    end
    result
  end

  def close
    ws.on :close do
      p [:close, event.code]
      ws = nil
      EM.stop
    end
  end
end
