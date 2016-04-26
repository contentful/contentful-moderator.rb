require 'mail'
require 'contentful/webhook/listener/controllers/webhook_aware'

module Contentful
  module Moderator
    class Controller < ::Contentful::Webhook::Listener::Controllers::WebhookAware
      def auto_save
        return unless webhook.entry?
        return unless notificable?(webhook)
        logger.debug("Workflow Webhook Received for '#{webhook.space_id}/#{webhook.id}': Checking for Notifications")

        emails = []
        emails << notify_authors(webhook) if notify_author?(webhook)
        emails << notify_reviewers(webhook) if notify_reviewer?(webhook)

        send_emails(emails)

        logger.debug("\tDone!")
      end
      alias_method :save, :auto_save

      def config
        ::Contentful::Moderator.config
      end

      def send_emails(emails)
        emails.each do |email|
          email.deliver!
        end
      end

      def notify_authors(webhook)
        logger.debug("\tCreating Author Notification Email")
        this = self
        ::Mail.new do
          from this.config.mail_origin
          to this.config.authors
          subject this.reviewer_field(webhook).email_subject
          body this.email_body(:reviewer, webhook)
        end
      end

      def notify_reviewers(webhook)
        logger.debug("\tCreating Reviewer Notification Email")
        this = self
        ::Mail.new do
          from this.config.mail_origin
          to this.config.editors
          subject this.author_field(webhook).email_subject
          body this.email_body(:author, webhook)
        end
      end

      def email_body(type, webhook)
        self.send("#{type}_field", webhook).email_body.gsub("'webhook_url'", webhook_url(webhook))
      end

      def webhook_content_type(webhook)
        webhook.sys['contentType']['sys']['id']
      end

      def content_type(webhook)
        config.content_types[webhook_content_type(webhook)]
      end

      def notificable?(webhook)
        config.content_types.keys.include?(webhook_content_type(webhook))
      end

      def notify_author?(webhook)
        field = webhook.fields[reviewer_field(webhook).field_id]
        if field.is_a? Hash
          return field[field.keys.first] == reviewer_field(webhook).notify_author_on
        else
          return field == reviewer_field(webhook).notify_author_on
        end
      end

      def notify_reviewer?(webhook)
        field = webhook.fields[author_field(webhook).field_id]
        if field.is_a? Hash
          return field[field.keys.first] == author_field(webhook).notify_reviewer_on
        else
          return field == author_field(webhook).notify_reviewer_on
        end
      end

      def author_field(webhook)
        content_type(webhook).author_field
      end

      def reviewer_field(webhook)
        content_type(webhook).reviewer_field
      end

      def webhook_url(webhook)
        "https://app.contentful.com/spaces/#{webhook.space_id}/entries/#{webhook.id}"
      end
    end
  end
end
