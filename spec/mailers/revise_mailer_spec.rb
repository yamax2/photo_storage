require 'rails_helper'

RSpec.describe ReviseMailer do
  describe '#failed' do
    let(:info) { {} }
    let(:admin_emails) { %w[max@tretyakov-ma.ru scott@evil.pro] }

    before do
      allow(Rails.application.config).to receive(:admin_emails).and_return(admin_emails)
    end

    subject { described_class.failed('000/013/', 10, info).deliver_now }

    context 'when without admin_emails' do
      let(:admin_emails) { [] }
      let(:info) { {1 => %w[test test]} }

      it { is_expected.not_to be_present }
    end

    context 'when without info' do
      it { is_expected.not_to be_present }
    end

    context 'when info presents' do
      let(:info) { {1 => %w[test qq], 2 => %w[error1 error2]} }

      it do
        expect(subject.to).to match_array(%w[max@tretyakov-ma.ru scott@evil.pro])
        expect(subject.subject).to eq I18n.t('views.revise_mailer.failed.subject', token_id: 10, dir: '000/013/')
        expect(subject.body.encoded).to include('table')
      end
    end
  end
end