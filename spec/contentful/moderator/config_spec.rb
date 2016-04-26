require 'spec_helper'

describe Contentful::Moderator::Config do
  let(:valid_params) { {
    content_types: ['foo'],
    authors: ['john@example.com'],
    editors: ['doe@example.com'],
    mail_origin: 'admin@example.com',
    mailer_settings: {
      connection_type: 'smtp',
      address: 'smtp.gmail.com',
      port: 587,
      domain: 'example.com',
      user_name: "'env_mailer_username'",
      password: "'env_mailer_password'",
      authentication: 'plain',
      enable_starttls_auto: true
    }
  } }
  subject { described_class.new(valid_params) }
  describe 'initialization' do
    it 'requires content types' do
      expect { described_class.new }.to raise_error ':content_types not set'
      expect { described_class.new(
        content_types: []
      ) }.to raise_error ':content_types not set'
    end

    it 'requires authors' do
      expect { described_class.new(
        content_types: ['foo']
      ) }.to raise_error ':authors not set'
      expect { described_class.new(
        content_types: ['foo'],
        authors: []
      ) }.to raise_error ':authors not set'
    end

    it 'requires editors' do
      expect { described_class.new(
        content_types: ['foo'],
        authors: ['john@example.com']
      ) }.to raise_error ':editors not set'
      expect { described_class.new(
        content_types: ['foo'],
        authors: ['john@example.com'],
        editors: []
      ) }.to raise_error ':editors not set'
    end

    it 'requires mail_origin' do
      expect { described_class.new(
        content_types: ['foo'],
        authors: ['john@example.com'],
        editors: ['doe@example.com']
      ) }.to raise_error ':mail_origin not set'
    end

    it 'requires mailer_settings' do
      expect { described_class.new(
        content_types: ['foo'],
        authors: ['john@example.com'],
        editors: ['doe@example.com'],
        mail_origin: 'admin@example.com'
      ) }.to raise_error ':mailer_settings not properly configured'
    end

    it 'has all it needs' do
      expect { subject }.not_to raise_error
    end

    describe ':port' do
      it 'sets a default port' do
        expect(subject.port).to eq described_class::DEFAULT_PORT
      end

      it 'can be overridden with an environment variable' do
        ENV['PORT'] = '1234'
        expect(subject.port).to eq 1234
        ENV['PORT'] = nil
      end

      it 'can be set manually' do
        config = described_class.new(
          valid_params.merge(port: 123123)
        )
        expect(config.port).to eq 123123
      end
    end

    describe ':endpoint' do
      it 'sets a default endpoint' do
        expect(subject.endpoint).to eq described_class::DEFAULT_ENDPOINT
      end

      it 'can be set manually' do
        config = described_class.new(
          valid_params.merge(endpoint: '/foo')
        )
        expect(config.endpoint).to eq '/foo'
      end
    end
  end

  it 'can be loaded with a yaml file' do
    config = described_class.load(File.join(Dir.pwd, 'spec', 'fixtures', 'config.yml'))
    expect(config.editors).to eq ['editor@example.com']
  end

  it 'configures mailer' do
    expect(Mail).to receive(:defaults)

    subject
  end

  describe ':mailer_username' do
    it "uses environment variable if set to 'env_mailer_username'" do
      ENV['ENV_MAILER_USERNAME'] = 'foobar'

      expect(subject.mailer_username).to eq 'foobar'

      ENV['ENV_MAILER_USERNAME'] = nil
    end

    it 'uses value otherwise' do
      valid_params[:mailer_settings][:user_name] = 'bob'
      expect(described_class.new(valid_params).mailer_username).to eq 'bob'
    end
  end

  describe ':mailer_password' do
    it "uses environment variable if set to 'env_mailer_password'" do
      ENV['ENV_MAILER_PASSWORD'] = 'foobar'

      expect(subject.mailer_password).to eq 'foobar'

      ENV['ENV_MAILER_PASSWORD'] = nil
    end

    it 'uses value otherwise' do
      valid_params[:mailer_settings][:password] = 'bob'
      expect(described_class.new(valid_params).mailer_password).to eq 'bob'
    end
  end
end
