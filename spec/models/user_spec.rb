# frozen_string_literal: true

RSpec.describe User do
  let(:user) { described_class.new(header) }

  context 'when empty header' do
    let(:header) { nil }

    it do
      expect(user).to be_admin
      expect(user).to have_attributes(user_name: nil)
    end
  end

  context 'when user is admin' do
    let(:header) { "Basic #{Base64.encode64('admin:pass')}" }

    it do
      expect(user).to be_admin
      expect(user).to have_attributes(user_name: 'admin')
    end
  end

  context 'when user is not an admin' do
    let(:header) { "Basic #{Base64.encode64('user:pass')}" }

    it do
      expect(user).not_to be_admin
      expect(user).to have_attributes(user_name: 'user')
    end
  end

  context 'when wrong auth type' do
    let(:header) { 'zozo' }

    it do
      expect { user.admin? }.to raise_error(/wrong auth type/)
    end
  end
end
