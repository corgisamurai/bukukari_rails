require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)

module Bukukari
  class Application < Rails::Application
    config.load_defaults 5.1
    config.autoload_paths += Dir["#{config.root}/batch/**/"]
  end
end
