# frozen_string_literal: true

RSpec.describe Yandex::CreateOrUpdateTokenJob do
  before do
    allow(Yandex::CreateOrUpdateTokenService).to receive(:call!)

    described_class.new.perform('999')
  end

  it do
    expect(Yandex::CreateOrUpdateTokenService).to have_received(:call!).with(code: '999')
  end
end
