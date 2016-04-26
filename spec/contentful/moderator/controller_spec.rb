require 'spec_helper'

describe Contentful::Moderator::Controller do
  let(:server) { MockServer.new }
  let(:logger) { Contentful::Webhook::Listener::Support::NullLogger.new }
  let(:timeout) { 10 }
  let(:headers) { {'X-Contentful-Topic' => 'ContentfulManagement.Entry.save', 'X-Contentful-Webhook-Name' => 'SomeName'} }
  let(:body) {
    {
      sys: {
        id: 'foo',
        space: {
          sys: {
            id: 'space_foo'
          }
        },
        contentType: {
          sys: {
            id: 'post'
          }
        }
      },
      fields: {
        author_field: { 'en-US' => nil },
        reviewer_field: { 'en-US' => nil }
      }
    }
  }
  subject { described_class.new server, logger, timeout }

  before :each do
    Contentful::Moderator.config = Contentful::Moderator::Config.load(File.join(Dir.pwd, 'spec', 'fixtures', 'config.yml'))
  end

  describe 'controller methods' do
    describe ':save' do
      describe 'does nothing' do
        it 'when webhook is asset' do
          headers['X-Contentful-Topic'] = 'ContentfulManagement.Asset.save'
          webhook = Contentful::Webhook::Listener::WebhookFactory.new(RequestDummy.new(headers, body)).create

          expect(webhook.asset?).to be_truthy
          expect(webhook.entry?).to be_falsey

          expect(subject).not_to receive(:notificable?)
          subject.respond(RequestDummy.new(headers, body), MockResponse.new).join
        end

        it 'when webhook is content type' do
          headers['X-Contentful-Topic'] = 'ContentfulManagement.ContentType.save'
          webhook = Contentful::Webhook::Listener::WebhookFactory.new(RequestDummy.new(headers, body)).create

          expect(webhook.content_type?).to be_truthy
          expect(webhook.entry?).to be_falsey

          expect(subject).not_to receive(:notificable?)
          subject.respond(RequestDummy.new(headers, body), MockResponse.new).join
        end

        it 'when webhook is entry but not notificable' do
          body[:sys][:contentType][:sys][:id] = 'foo'
          webhook = Contentful::Webhook::Listener::WebhookFactory.new(RequestDummy.new(headers, body)).create

          expect(webhook.entry?).to be_truthy

          expect(subject).to receive(:notificable?).and_call_original
          expect(subject).not_to receive(:notify_author?)
          subject.respond(RequestDummy.new(headers, body), MockResponse.new).join
        end

        it 'when no notification flag is set' do
          expect(subject).to receive(:send_emails).with([])
          subject.respond(RequestDummy.new(headers, body), MockResponse.new).join
        end
      end

      it 'sends author notification' do
        body[:fields][:reviewer_field] = 'Needs further editing'

        expect(subject).to receive(:notify_authors) { 'author_notification' }
        expect(subject).to receive(:send_emails).with(['author_notification'])

        subject.respond(RequestDummy.new(headers, body), MockResponse.new).join
      end

      it 'sends editor notification' do
        body[:fields][:author_field] = 'Ready for review'

        expect(subject).to receive(:notify_reviewers) { 'editor_notification' }
        expect(subject).to receive(:send_emails).with(['editor_notification'])

        subject.respond(RequestDummy.new(headers, body), MockResponse.new).join
      end

      it 'sends both notifications' do
        body[:fields][:reviewer_field] = 'Needs further editing'
        body[:fields][:author_field] = 'Ready for review'

        expect(subject).to receive(:notify_authors) { 'author_notification' }
        expect(subject).to receive(:notify_reviewers) { 'editor_notification' }
        expect(subject).to receive(:send_emails).with(['author_notification', 'editor_notification'])

        subject.respond(RequestDummy.new(headers, body), MockResponse.new).join
      end
    end
  end

  describe 'instance methods' do
    let(:webhook) { Contentful::Webhook::Listener::WebhookFactory.new(RequestDummy.new(headers, body)).create }

    it ':config' do
      expect(subject.config).to eq Contentful::Moderator.config
    end

    it ':send_emails' do
      email = Object.new

      expect(email).to receive(:deliver!)

      subject.send_emails([email])
    end

    it ':notify_authors' do
      email = subject.notify_authors(webhook).to_s

      expect(email).to include("From: #{subject.config.mail_origin}")
      expect(email).to include("To: #{subject.config.authors.join('')}")
      expect(email).to include(subject.webhook_url(webhook))
    end

    it ':notify_reviewers' do
      email = subject.notify_reviewers(webhook).to_s

      expect(email).to include("From: #{subject.config.mail_origin}")
      expect(email).to include("To: #{subject.config.editors.join('')}")
      expect(email).to include(subject.webhook_url(webhook))
    end

    describe ':notificable?' do
      it 'returns true if content type is present in config' do
        expect(subject.notificable?(webhook)).to be_truthy
      end

      it 'returns false if content type is not present in config' do
        body[:sys][:contentType][:sys][:id] = 'foo'
        webhook = Contentful::Webhook::Listener::WebhookFactory.new(RequestDummy.new(headers, body)).create 

        expect(subject.notificable?(webhook)).to be_falsey
      end
    end

    describe ':notify_reviewer?' do
      it 'returns false if value doesnt match expected' do
        expect(subject.notify_reviewer?(webhook)).to be_falsey
      end

      it 'returns true if value matches config' do
        body[:fields][:author_field]['en-US'] = 'Ready for review'
        webhook = Contentful::Webhook::Listener::WebhookFactory.new(RequestDummy.new(headers, body)).create 

        expect(subject.notify_reviewer?(webhook)).to be_truthy

        body[:fields][:author_field] = 'Ready for review'
        webhook = Contentful::Webhook::Listener::WebhookFactory.new(RequestDummy.new(headers, body)).create 

        expect(subject.notify_reviewer?(webhook)).to be_truthy
      end
    end

    describe ':notify_author?' do
      it 'returns false if value doesnt match expected' do
        expect(subject.notify_author?(webhook)).to be_falsey
      end

      it 'returns true if value matches config' do
        body[:fields][:reviewer_field]['en-US'] = 'Needs further editing'
        webhook = Contentful::Webhook::Listener::WebhookFactory.new(RequestDummy.new(headers, body)).create 

        expect(subject.notify_author?(webhook)).to be_truthy

        body[:fields][:reviewer_field] = 'Needs further editing'
        webhook = Contentful::Webhook::Listener::WebhookFactory.new(RequestDummy.new(headers, body)).create 

        expect(subject.notify_author?(webhook)).to be_truthy
      end
    end

    it ':webhook_content_type' do
      expect(subject.webhook_content_type(webhook)).to eq 'post'
    end

    describe ':content_type' do
      it 'returns configuration for a content type' do
        expect(subject.content_type(webhook)).to be_a Hash
        expect(subject.content_type(webhook).author_field.field_id).to eq 'author_field'
      end

      it 'returns nil if content type is not configured' do
        body[:sys][:contentType][:sys][:id] = 'foo'
        webhook = Contentful::Webhook::Listener::WebhookFactory.new(RequestDummy.new(headers, body)).create 

        expect(subject.content_type(webhook)).to eq nil
      end
    end

    it ':author_field' do
      expect(subject.author_field(webhook)).to be_a Hash
      expect(subject.author_field(webhook).field_id).to eq 'author_field'
      expect(subject.author_field(webhook).notify_reviewer_on).to eq 'Ready for review'
    end

    it ':reviewer_field' do
      expect(subject.reviewer_field(webhook)).to be_a Hash
      expect(subject.reviewer_field(webhook).field_id).to eq 'reviewer_field'
      expect(subject.reviewer_field(webhook).notify_author_on).to eq 'Needs further editing'
    end

    it ':webhook_url' do
      expect(subject.webhook_url(webhook)).to eq 'https://app.contentful.com/spaces/space_foo/entries/foo'
    end

    describe ':email_body' do
      it 'for reviewer' do
        body[:fields][:author_field] = 'Ready for review'
        webhook = Contentful::Webhook::Listener::WebhookFactory.new(RequestDummy.new(headers, body)).create 

        expect(subject.email_body(:author, webhook)).to eq <<-BODY
Dear Editor Team,

The entry https://app.contentful.com/spaces/space_foo/entries/foo is ready for review.

Cordially,
Moderator Bot
        BODY
      end

      it 'for author' do
        body[:fields][:reviewer_field] = 'Needs further editing'
        webhook = Contentful::Webhook::Listener::WebhookFactory.new(RequestDummy.new(headers, body)).create 

        expect(subject.email_body(:reviewer, webhook)).to eq <<-BODY
Dear Authoring Team,

The entry https://app.contentful.com/spaces/space_foo/entries/foo requires further editing.

Cordially,
Moderator Bot
          BODY
      end
    end
  end
end
