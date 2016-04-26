require 'logger'
require 'hashie'
require 'contentful/webhook/listener'
require 'contentful/moderator/version'
require 'contentful/moderator/config'
require 'contentful/moderator/controller'

module Contentful
  module Moderator
    @@config = nil

    def self.config=(config)
      @@config ||= (config.is_a? ::Contentful::Moderator::Config) ? config : ::Contentful::Moderator::Config.new(config)
    end

    def self.config
      @@config
    end

    def self.start(config = {})
      fail "Moderator not configured" if config.nil? && !block_given?

      if block_given?
        yield(config) if block_given?
      end
      self.config = config

      logger = Logger.new(STDOUT)
      ::Contentful::Webhook::Listener::Server.start do |server_config|
        server_config[:port] = config.port
        server_config[:logger] = logger
        server_config[:endpoints] = [
          {
            endpoint: config.endpoint,
            controller: ::Contentful::Moderator::Controller,
            timeout: 0
          }
        ]
      end.join
    end
  end
end
