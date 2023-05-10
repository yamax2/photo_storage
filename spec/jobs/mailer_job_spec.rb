# frozen_string_literal: true

RSpec.describe MailerJob, type: :mailer do
  subject(:send!) { described_class.new.perform(*args) }

  let(:admin_emails) { %w[max@tretyakov-ma.ru scott@evil.pro] }

  before do
    allow(Rails.application.config).to receive(:admin_emails).and_return(admin_emails)
  end

  context 'when correct args' do
    let(:args) do
      [
        'ReviseMailer',
        'failed',
        [
          '/test/',
          1,
          1,
          {1 => %w[something wrong]}
        ]
      ]
    end

    it do
      expect { send! }.not_to raise_error
    end
  end

  context 'when incorrect args' do
    let(:args) do
      [
        'ReviseMailer',
        'failed',
        ['/test/', 1]
      ]
    end

    it do
      expect { send! }.to raise_error(ArgumentError)
    end
  end
end
