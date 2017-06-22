require 'rails_helper'

describe 'Bot' do
  it '#run' do
    expect(Bot.sample).to eq 'works'
  end
end
