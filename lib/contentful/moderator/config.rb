require 'hashie'
require 'yaml'

module Contentful
  module Moderator
    class Config
      DEFAULT_PORT = 33123
      DEFAULT_ENDPOINT = '/moderator'

      attr_reader :config

      def self.load(path)
        new(Hashie::Mash.load(path))
      end

      def initialize(config = {})
        @config = Hashie::Mash.new(config)

        @config.port = (ENV.key?('PORT') ? ENV['PORT'].to_i : DEFAULT_PORT) unless @config.port?
        @config.endpoint = DEFAULT_ENDPOINT unless @config.endpoint?

        fail ':content_types not set' unless @config.content_types? && !@config.content_types.empty?
        fail ':authors not set' unless @config.authors? && !@config.authors.empty?
        fail ':editors not set' unless @config.editors? && !@config.editors.empty?
        fail ':mail_origin not set' unless @config.mail_origin?
        fail ':mailer_settings not properly configured' unless mailer_configured?

        configure_mailer
      end

      def port
        @config.port
      end

      def endpoint
        @config.endpoint
      end

      def authors
        @config.authors
      end

      def editors
        @config.editors
      end

      def content_types
        @config.content_types
      end

      def mail_origin
        @config.mail_origin
      end

      def mailer_settings
        @config.mailer_settings
      end

      def mailer_username
        return ENV['ENV_MAILER_USERNAME'] if config.mailer_settings.user_name == "'env_mailer_username'"
        config.mailer_settings.user_name
      end

      def mailer_password
        return ENV['ENV_MAILER_PASSWORD'] if config.mailer_settings.password == "'env_mailer_password'"
        config.mailer_settings.password
      end

      def mailer_configured?
        return false unless @config.mailer_settings?
        return false unless @config.mailer_settings.connection_type
        return false unless @config.mailer_settings.address
        return false unless @config.mailer_settings.port
        return false unless @config.mailer_settings.domain

        # Optionals - Explicitly left here as reminder
        #
        # return false unless @config.mailer_settings.user_name
        # return false unless @config.mailer_settings.password
        # return false unless @config.mailer_settings.authentication
        # return false unless @config.mailer_settings.enable_starttls_auto
        # return false unless @config.mailer_settings.openssl_verify_mode
        # return false unless @config.mailer_settings.ssl
        # return false unless @config.mailer_settings.tls

        true
      end

      def configure_mailer
        this = self
        Mail.defaults do
          delivery_method this.config.mailer_settings.connection_type.to_sym, {
            address: this.config.mailer_settings.address,
            port: this.config.mailer_settings.port,
            domain: this.config.mailer_settings.domain,
            user_name: this.mailer_username,
            password: this.mailer_password,
            authentication: this.config.mailer_settings.authentication,
            enable_starttls_auto: this.config.mailer_settings.enable_starttls_auto,
            openssl_verify_mode: this.config.mailer_settings.openssl_verify_mode,
            ssl: this.config.mailer_settings.ssl,
            tls: this.config.mailer_settings.tls
          }
        end
      end
    end
  end
end
