require 'rails_helper'

RSpec.describe Yandex::CreateOrUpdateTokenJob do
  before do
    allow(Yandex::CreateOrUpdateTokenService).to receive(:call!)

    described_class.perform_async('999')
  end

  it do
    expect(Yandex::CreateOrUpdateTokenService).to have_received(:call!).with(code: '999')
  end
end
