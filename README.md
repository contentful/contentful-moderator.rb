# Contentful Moderator

> This gem has been superseded by a product feature. You can read more here: https://www.contentful.com/blog/2019/10/22/content-operations-easier-scheduled-publishing-comments-tasks/

Moderator Server listens for incoming webhooks from Contentful to manage moderation workflows of entries.

## Contentful
[Contentful](https://www.contentful.com) provides a content infrastructure for digital teams to power content in websites, apps, and devices. Unlike a CMS, Contentful was built to integrate with the modern software stack. It offers a central hub for structured content, powerful management and delivery APIs, and a customizable web app that enable developers and content creators to ship digital products faster.

## What does `contentful-moderator` do?
The aim of `contentful-moderator` is to have developers setting up their Contentful
entries for moderated authoring workflows.

### What is a moderated authoring workflow?

We'll explain this with a step-by-step example:

1. Author creates an entry
2. Author edits an entry
3. Author submits for Review
4. System triggers Moderation Webhook
5. `contentful-moderator` sends email to Reviewer Team
6. Reviewer checks entry
  1. Reviewer approves entry and publishes - *Workflow ends*
  2. Reviewer considers edits are required and submits for further editing
7. System triggers Moderation Webhook
8. `contentful-moderator` sends email to Authoring Team
9. Go back to 2

## How does it work
`contentful-moderator` provides a web endpoint to receive webhook calls from Contentful.

Every time the endpoint recieves a call it looks for the value of the fields defined in the configuration.

If any of the values match the configuration, it will send an email to the specified queue (authors or editors).

You can add multiple content types to your configuration.

## Requirements

* An SMTP Server (like `postfix` or a GMail/Yahoo/MSN account with SMTP support)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'contentful-moderator'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install contentful-moderator

## Usage

* Create your configuration file:

You can base your configuration file from [the example `config.yml`](./example/config.yml)

```yml
---

endpoint: '/moderator' # Optional - defaults to '/moderator'
port: 33123 # Optional - defaults to ENV['PORT'] or 33123
content_types:
  post: # ID of your Content Type (multiple Content Types can be set here)
    author_field: # Required
      field_id: 'author_field'
      notify_reviewer_on: 'Ready for review' # Value to match - this is Exact match
      email_subject: 'A submission requires review'
      email_body: > # 'webhook_url' will get replaced with the Entry URL in the Contentful Web App
          Dear Editor Team,


          The entry 'webhook_url' is ready for review.


          Cordially,


          Moderator Bot
    reviewer_field: # Required
      field_id: 'reviewer_field'
      notify_author_on: 'Needs further editing'
      email_subject: 'A submission requires further editing'
      email_body: >
          Dear Authoring Team,


          The entry 'webhook_url' requires further editing.


          Cordially,


          Moderator Bot
authors: # Required - List of Author Emails
  - 'author@example.com'
editors: # Required - List of Editor Emails
  - 'editor@example.com'
mail_origin: 'admin@example.com' # Required - Email from which the messages will be sent (on GMail this does not take effect)
mailer_settings: # Required
  connection_type: 'smtp'
  address: 'smtp.gmail.com'
  port: 587
  domain: 'example.com'
  user_name: "'env_mailer_username'" # Username can be Plain-Text. But 'env_mailer_username' will get replaced with ENV['ENV_MAILER_USERNAME']
  password: "'env_mailer_password'" # Same as for user_name. 'env_mailer_password' will get replaced with ENV['ENV_MAILER_PASSWORD']
  authentication: 'plain'
  enable_starttls_auto: true
```

* Run the server:

```bash
$ contentful_moderator config.yml
```

* Configure the webhook in Contentful:

Under the space settings menu choose webhook and add a new webhook pointing to `http://YOUR_SERVER:33123/moderator`.

Keep in mind that if you modify the defaults, the URL should be changed to the values specified in the configuration.

## Running in Heroku

* Create a `Procfile` containing:

```
web: PORT=$PORT env bundle exec contentful_moderator config.yml
```

That will allow Heroku to set it's own Port according to their policy.

Make sure to set your Username/Password environment variables (if you're using them).

Then proceed to `git push heroku master`.

The URL for the webhook then will be on port 80, so you should change it to: `http://YOUR_APPLICATION/moderator`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/contentful/contentful-moderator.rb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
