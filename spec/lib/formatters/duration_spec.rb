# frozen_string_literal: true

RSpec.describe Formatters::Duration do
  subject { described_class.new(duration).call }

  context 'when without hours' do
    let(:duration) { 59.minutes + 29.seconds }

    it { is_expected.to eq('59мин.') }
  end

  context 'when hours and minutes' do
    let(:duration) { 2.hours + 59.minutes + 29.seconds }

    it { is_expected.to eq('2ч. 59мин.') }
  end

  context 'when round up' do
    let(:duration) { 2.hours + 59.minutes + 39.seconds }

    it { is_expected.to eq('3ч.') }
  end

  context 'when zero minutes' do
    let(:duration) { 10.hours }

    it { is_expected.to eq('10ч.') }
  end

  context 'when zero' do
    let(:duration) { 28.seconds }

    it { is_expected.to eq('0') }
  end

  context 'when minutes < 10' do
    let(:duration) { 1.hour + 5.minutes + 59.seconds }

    it { is_expected.to eq('1ч. 06мин.') }
  end

  context 'when days' do
    let(:duration) { 10.days + 1.hour + 5.minutes + 55.seconds }

    it { is_expected.to eq('10дн. 1ч. 06мин.') }
  end

  context 'when days roundup' do
    let(:duration) { 23.hours + 59.minutes + 55.seconds }

    it { is_expected.to eq('1дн.') }
  end

  context 'when seconds' do
    subject { described_class.new(duration, include_seconds: true).call }

    let(:duration) { 125.seconds }

    it { is_expected.to eq('02мин. 05сек.') }
  end

  context 'when mode with seconds but value without seconds' do
    subject { described_class.new(duration, include_seconds: true).call }

    let(:duration) { 120.seconds }

    it { is_expected.to eq('02мин.') }
  end
end
